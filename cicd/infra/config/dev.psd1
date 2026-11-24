@{
    Profile = 'cicd-deploy'
    Region = 'ap-northeast-1'
    ExpectedAccount = '572535616215'
    Parameters = @{
        ProjectName = 'java-ecs-demo'
        Environment = 'dev'
        GitHubRepository = 'mystylezfzjp-eng/cicd-java-ecs-demo'
        GitHubBranch = 'main'
        ConnectionArn = 'arn:aws:codeconnections:ap-northeast-1:572535616215:connection/15f2411e-458c-4d2e-a3b8-cc04ee2594f8'
    }
}
