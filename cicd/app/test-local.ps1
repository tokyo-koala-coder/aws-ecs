[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$pom = Join-Path $PSScriptRoot 'pom.xml'
mvn -B -ntp -f $pom clean verify
if ($LASTEXITCODE -ne 0) {
    throw 'Maven verification failed.'
}
