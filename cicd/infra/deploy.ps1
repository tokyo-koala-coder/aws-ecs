[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config/dev.psd1'),
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

# The data file selects an environment. The AWS CLI loads credentials from the local profile.
$config = Import-PowerShellDataFile -LiteralPath $ConfigPath
$parameters = $config.Parameters

if ($config.ExpectedAccount -notmatch '^[0-9]{12}$' -or
    [string]::IsNullOrWhiteSpace($config.Profile) -or
    [string]::IsNullOrWhiteSpace($config.Region)) {
    throw 'Set Profile, Region, and a 12-digit ExpectedAccount in the deployment config.'
}

foreach ($key in @('ProjectName', 'Environment', 'GitHubRepository', 'GitHubBranch', 'ConnectionArn')) {
    if ([string]::IsNullOrWhiteSpace($parameters[$key])) {
        throw "Set Parameters.$key in $ConfigPath."
    }
}

$region = [regex]::Escape($config.Region)
$account = [regex]::Escape($config.ExpectedAccount)
if ($parameters.ConnectionArn -cnotmatch "^arn:[a-z0-9-]+:(codeconnections|codestar-connections):${region}:${account}:connection/[a-zA-Z0-9-]+$") {
    throw 'ConnectionArn must belong to the configured AWS account and region.'
}

$awsTarget = @('--profile', $config.Profile, '--region', $config.Region, '--no-cli-pager')

# Check the authenticated account before submitting a change set.
$callerAccount = aws sts get-caller-identity @awsTarget --query Account --output text
if ($LASTEXITCODE -ne 0 -or $callerAccount -ne $config.ExpectedAccount) {
    throw "AWS account verification failed for profile '$($config.Profile)'."
}

$connectionJson = aws codeconnections get-connection @awsTarget --connection-arn $parameters.ConnectionArn --query Connection --output json
if ($LASTEXITCODE -ne 0) {
    throw 'Could not verify the GitHub connection. Check the ARN and codeconnections:GetConnection permission.'
}
$connection = $connectionJson | ConvertFrom-Json
if ($connection.ProviderType -ne 'GitHub' -or $connection.ConnectionStatus -ne 'AVAILABLE') {
    throw 'ConnectionArn must refer to a GitHub connection in AVAILABLE status.'
}

$stackName = "$($parameters.ProjectName)-$($parameters.Environment)-pipeline"
$templateFile = Join-Path $PSScriptRoot 'pipeline.yml'
$parameterOverrides = $parameters.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }

# Default to a reviewable change set. Apply opts in to executing the deployment.
$deployMode = @()
if (-not $Apply) {
    $deployMode = @('--no-execute-changeset')
}

Write-Host "Stack $stackName, account $($config.ExpectedAccount), region $($config.Region)"
aws cloudformation deploy @awsTarget @deployMode --stack-name $stackName --template-file $templateFile `
    --capabilities CAPABILITY_IAM --no-fail-on-empty-changeset --parameter-overrides @parameterOverrides
if ($LASTEXITCODE -ne 0) {
    throw "CloudFormation deployment command failed for $stackName."
}
