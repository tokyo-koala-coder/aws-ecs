[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$null = Confirm-ProjectAccount

foreach ($template in @('pipeline.yml', 'service.yml')) {
    $templatePath = Join-Path (Split-Path -Parent $PSScriptRoot) $template
    Invoke-ProjectAws cloudformation validate-template --template-body "file://$templatePath"
}

& (Join-Path $PSScriptRoot '../deploy.ps1') -ConfigPath $ConfigPath
