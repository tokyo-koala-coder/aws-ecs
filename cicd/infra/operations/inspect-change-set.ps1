[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ChangeSetArn,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$null = Confirm-ProjectAccount

Invoke-ProjectAws cloudformation describe-change-set --change-set-name $ChangeSetArn `
    --query 'Changes[].ResourceChange.{Action:Action,Resource:LogicalResourceId,Type:ResourceType}' --output table
