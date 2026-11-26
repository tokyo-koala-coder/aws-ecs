[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$null = Confirm-ProjectAccount

Invoke-ProjectAws codepipeline start-pipeline-execution --name $pipeline --output json
