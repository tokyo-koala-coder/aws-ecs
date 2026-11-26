function Get-ProjectStackStatus {
    param([string]$StackName)

    # DescribeStacks reports an absent stack as a ValidationError. Preserve other failures.
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $result = aws cloudformation describe-stacks @awsTarget --stack-name $StackName `
        --query 'Stacks[0].StackStatus' --output text 2>&1
    if ($LASTEXITCODE -eq 0) {
        return $result
    }

    $missingStack = 'ValidationError.*Stack with id ' + [regex]::Escape($StackName) + ' does not exist'
    if (($result -join "`n") -notmatch $missingStack) {
        throw "Could not describe $StackName. $result"
    }
}

function Get-DeployStage {
    Invoke-ProjectAws codepipeline get-pipeline-state --name $pipeline `
        --query "stageStates[?stageName=='Deploy'] | [0].{Inbound:inboundTransitionState.enabled,Status:latestExecution.status,Actions:actionStates[].{Name:actionName,Status:latestExecution.status}}" `
        --output json | ConvertFrom-Json
}

function Assert-DeployStagePaused {
    param($Stage)

    if ($null -eq $Stage -or $Stage.Inbound -ne $false) {
        throw 'The Deploy stage inbound transition must be disabled before stack deletion.'
    }
    if ($Stage.Status -in 'InProgress', 'Stopping' -or $Stage.Actions.Status -contains 'InProgress') {
        throw 'Deploy is still running. Wait for it to finish before continuing.'
    }
}
