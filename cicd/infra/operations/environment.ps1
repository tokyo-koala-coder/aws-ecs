# Optional: Override default AWS configuration paths
# $env:AWS_CONFIG_FILE = 'D:\aws\config'
# $env:AWS_SHARED_CREDENTIALS_FILE = 'D:\aws\credentials'

# Load and validate the selected environment config.
$config = Import-PowerShellDataFile -LiteralPath $ConfigPath
if ($config.ExpectedAccount -notmatch '^[0-9]{12}$' -or
    -not $config.Profile -or -not $config.Region -or
    -not $config.Parameters.ProjectName -or -not $config.Parameters.Environment) {
    throw 'Set Profile, Region, ExpectedAccount, ProjectName, and Environment in the AWS config.'
}

$awsTarget = @('--profile', $config.Profile, '--region', $config.Region, '--no-cli-pager')
$pipeline = "$($config.Parameters.ProjectName)-$($config.Parameters.Environment)"
$pipelineStack = "$pipeline-pipeline"
$serviceStack = "$pipeline-service"

function Invoke-ProjectAws {
    aws @args @awsTarget
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: $($args[0..1] -join ' ')."
    }
}

function Confirm-ProjectAccount {
    $identity = Invoke-ProjectAws sts get-caller-identity --output json | ConvertFrom-Json
    if ($identity.Account -ne $config.ExpectedAccount) {
        throw "AWS account verification failed for profile '$($config.Profile)'. Expected $($config.ExpectedAccount), got $($identity.Account)."
    }

    Write-Host "Account $($identity.Account) / $($config.Region) / $pipeline"
    $identity
}
