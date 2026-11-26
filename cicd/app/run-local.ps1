[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$jar = Join-Path $PSScriptRoot 'target/app.jar'
if (-not (Test-Path -LiteralPath $jar -PathType Leaf)) {
    throw 'app.jar is missing. Run app/test-local.ps1 first.'
}

java -jar $jar
if ($LASTEXITCODE -ne 0) {
    throw 'The Java application exited with an error.'
}
