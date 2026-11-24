[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1'),
    [switch]$Configure
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')

if ($Configure) {
    aws configure --profile $config.Profile
    if ($LASTEXITCODE -ne 0) {
        throw 'AWS CLI profile configuration failed.'
    }
}

Confirm-ProjectAccount
