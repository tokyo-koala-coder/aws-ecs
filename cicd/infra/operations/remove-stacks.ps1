[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
. (Join-Path $PSScriptRoot 'cleanup-state.ps1')
$null = Confirm-ProjectAccount

if (-not $PSCmdlet.ShouldProcess("$serviceStack, then $pipelineStack", 'Delete CloudFormation stacks')) {
    return
}

$pipelineStatus = Get-ProjectStackStatus $pipelineStack
if ($pipelineStatus -and $pipelineStatus -notin 'DELETE_IN_PROGRESS', 'REVIEW_IN_PROGRESS') {
    Assert-DeployStagePaused (Get-DeployStage)
}

foreach ($stack in @($serviceStack, $pipelineStack)) {
    $status = Get-ProjectStackStatus $stack
    if (-not $status -or $status -eq 'DELETE_COMPLETE') {
        Write-Host "$stack is already absent."
        continue
    }
    if ($status -ne 'DELETE_IN_PROGRESS') {
        Invoke-ProjectAws cloudformation delete-stack --stack-name $stack
    }
    Invoke-ProjectAws cloudformation wait stack-delete-complete --stack-name $stack
    Write-Host "$stack deletion completed."
}
