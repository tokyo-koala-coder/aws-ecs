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

$projectRoot = Split-Path -Parent $PSScriptRoot
if ((Split-Path -Leaf $projectRoot) -cne 'cicd') {
    throw 'Place the project in a directory named cicd under the intended Git repository root.'
}

Push-Location (Split-Path -Parent $projectRoot)
try {
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0 -or (Test-Path -LiteralPath 'cicd/.git')) {
        throw 'A Git repository already exists here or above this directory. Use your normal commit and push workflow.'
    }

    Invoke-ProjectGit init -b $branch
    $projectPaths = @('.editorconfig', '.gitignore', 'AGENTS.md', 'CHANGELOG.md', 'README.md', 'manual.md', 'app', 'infra', 'scripts')
    if (Test-Path -LiteralPath 'cicd/lab.md') {
        $projectPaths += 'lab.md'
    }
    $repositoryPaths = $projectPaths | ForEach-Object { "cicd/$_" }
    Invoke-ProjectGit add '--' @repositoryPaths
    Invoke-ProjectGit commit -m 'Initialize Java ECS demo and infrastructure'
    Invoke-ProjectGit remote add origin "https://github.com/$repository.git"
    Invoke-ProjectGit push -u origin $branch
}
finally {
    Pop-Location
}
