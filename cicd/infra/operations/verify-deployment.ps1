[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '../config/dev.psd1'),
    [string]$LogSince = '1h'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'environment.ps1')
$null = Confirm-ProjectAccount

Write-Host 'Recent pipeline executions'
Invoke-ProjectAws codepipeline list-pipeline-executions --pipeline-name $pipeline --max-items 3 `
    --query 'pipelineExecutionSummaries[].{Id:pipelineExecutionId,Status:status}' --output table

Write-Host 'Service stack'
Invoke-ProjectAws cloudformation describe-stacks --stack-name $serviceStack `
    --query 'Stacks[0].StackStatus' --output text

Write-Host 'ECS service'
Invoke-ProjectAws ecs describe-services --cluster $pipeline --services $pipeline `
    --query 'services[0].{Status:status,Desired:desiredCount,Running:runningCount,TaskDefinition:taskDefinition}' --output json

Write-Host 'Scaling targets and policies'
Invoke-ProjectAws application-autoscaling describe-scalable-targets `
    --service-namespace ecs --resource-ids "service/$pipeline/$pipeline" `
    --query 'ScalableTargets[].{Min:MinCapacity,Max:MaxCapacity}' --output table
Invoke-ProjectAws application-autoscaling describe-scaling-policies `
    --service-namespace ecs --resource-id "service/$pipeline/$pipeline" `
    --query 'ScalingPolicies[].{Metric:TargetTrackingScalingPolicyConfiguration.PredefinedMetricSpecification.PredefinedMetricType,Target:TargetTrackingScalingPolicyConfiguration.TargetValue}' --output table

Write-Host 'ECS logs'
Invoke-ProjectAws logs tail "/ecs/$pipeline" --since $LogSince
