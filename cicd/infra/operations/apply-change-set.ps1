[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ChangeSetArn,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$null = Confirm-ProjectAccount

$changeSet = Invoke-ProjectAws cloudformation describe-change-set --change-set-name $ChangeSetArn `
    --query '{StackName:StackName,ExecutionStatus:ExecutionStatus,Import:Changes[?ResourceChange.Action==`Import`]}' --output json | ConvertFrom-Json
if ($changeSet.StackName -ne $pipelineStack -or $changeSet.ExecutionStatus -ne 'AVAILABLE' -or $changeSet.Import) {
    throw "The change set must be available for creating or updating $pipelineStack."
}

$stackStatus = Invoke-ProjectAws cloudformation describe-stacks --stack-name $pipelineStack `
    --query 'Stacks[0].StackStatus' --output text
$waiter = if ($stackStatus -eq 'REVIEW_IN_PROGRESS') { 'stack-create-complete' } else { 'stack-update-complete' }

Invoke-ProjectAws cloudformation execute-change-set --change-set-name $ChangeSetArn
Invoke-ProjectAws cloudformation wait $waiter --stack-name $pipelineStack
Invoke-ProjectAws cloudformation describe-stacks --stack-name $pipelineStack --query 'Stacks[0].StackStatus' --output text
