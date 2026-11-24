[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Invoke-RestMethod 'http://localhost:8080/'
Invoke-RestMethod 'http://localhost:8080/health'
