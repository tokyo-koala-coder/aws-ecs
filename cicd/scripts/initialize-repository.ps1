[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../infra/config/dev.psd1')
)

$ErrorActionPreference = 'Stop'

$config = Import-PowerShellDataFile -LiteralPath $ConfigPath
$repository = $config.Parameters.GitHubRepository
$branch = $config.Parameters.GitHubBranch
if ($repository -notmatch '^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$' -or -not $branch) {
    throw 'Set GitHubRepository (OWNER/REPO) and GitHubBranch in the environment config.'
}

function Invoke-ProjectGit {
    git @args
    if ($LASTEXITCODE -ne 0) {
        throw "Git $($args[0]) failed."
    }
}

Push-Location (Join-Path $PSScriptRoot '..')
try {
    if (Test-Path -LiteralPath .git) {
        throw 'This directory already has a Git repository. Use your normal commit and push workflow.'
    }

    Invoke-ProjectGit init -b $branch
    Invoke-ProjectGit add '--' .gitignore AGENTS.md CHANGELOG.md README.md manual.md lab.md app infra scripts
    Invoke-ProjectGit commit -m 'Initialize Java ECS demo and infrastructure'
    Invoke-ProjectGit remote add origin "https://github.com/$repository.git"
    Invoke-ProjectGit push -u origin $branch
}
finally {
    Pop-Location
}
