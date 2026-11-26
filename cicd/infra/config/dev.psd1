@{
    Profile = 'YOUR_AWS_PROFILE'
    Region = 'ap-northeast-1'
    ExpectedAccount = 'YOUR_AWS_ACCOUNT_ID'
    Parameters = @{
        ProjectName = 'ecs-pipeline'
        Environment = 'dev'
        GitHubRepository = 'YOUR_PROJET_REMOTE_ADDRESS'
        GitHubBranch = 'master'
        ConnectionArn = 'YOUR_ConnectionArn'
    }
}
