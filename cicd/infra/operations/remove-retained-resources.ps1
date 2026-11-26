[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [ValidatePattern('^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$')]
    [string]$ArtifactBucket,
    [string]$RepositoryName,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
. (Join-Path $PSScriptRoot 'cleanup-state.ps1')

if (-not $ArtifactBucket -and -not $RepositoryName) {
    throw 'Provide ArtifactBucket, RepositoryName, or both from the cleanup preparation output.'
}
if ($RepositoryName -and $RepositoryName -cne $pipeline) {
    throw "The repository name must match the configured name '$pipeline'."
}
$null = Confirm-ProjectAccount

foreach ($stack in @($serviceStack, $pipelineStack)) {
    $status = Get-ProjectStackStatus $stack
    if ($status -and $status -ne 'DELETE_COMPLETE') {
        throw "Delete $stack before removing retained resources. Current status: $status."
    }
}

if ($ArtifactBucket) {
    $versioning = Invoke-ProjectAws s3api get-bucket-versioning --bucket $ArtifactBucket `
        --expected-bucket-owner $config.ExpectedAccount --output json | ConvertFrom-Json
    if ($versioning.Status) {
        throw "Bucket $ArtifactBucket has versioning status $($versioning.Status). Remove all object versions and delete markers in the S3 console before deleting the bucket."
    }

    if ($PSCmdlet.ShouldProcess("s3://$ArtifactBucket", 'Permanently delete the bucket and all artifacts')) {
        Invoke-ProjectAws s3 rb "s3://$ArtifactBucket" --force
    }
}

if ($RepositoryName -and $PSCmdlet.ShouldProcess($RepositoryName, 'Permanently delete the ECR repository and all images')) {
    Invoke-ProjectAws ecr delete-repository --registry-id $config.ExpectedAccount --repository-name $RepositoryName --force --output json
}
