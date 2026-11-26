[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
. (Join-Path $PSScriptRoot 'cleanup-state.ps1')
$null = Confirm-ProjectAccount

$outputs = Invoke-ProjectAws cloudformation describe-stacks --stack-name $pipelineStack `
    --query 'Stacks[0].Outputs' --output json | ConvertFrom-Json
$bucket = ($outputs | Where-Object OutputKey -eq 'ArtifactBucketName').OutputValue
$repositoryUri = ($outputs | Where-Object OutputKey -eq 'RepositoryUri').OutputValue
$repository = ($repositoryUri -split '/', 2)[1]
if (-not $bucket -or -not $repository) {
    throw 'The pipeline stack outputs are missing the retained resource names.'
}

[pscustomobject]@{
    ServiceStack = $serviceStack
    PipelineStack = $pipelineStack
    ArtifactBucket = $bucket
    RepositoryName = $repository
    RepositoryUri = $repositoryUri
} | Format-List

if (-not $PSCmdlet.ShouldProcess($pipeline, 'Disable inbound transition to Deploy')) {
    return
}

Invoke-ProjectAws codepipeline disable-stage-transition --pipeline-name $pipeline `
    --stage-name Deploy --transition-type Inbound --reason 'Demo teardown'
$stage = Get-DeployStage
$stage | ConvertTo-Json -Depth 4
Assert-DeployStagePaused $stage
