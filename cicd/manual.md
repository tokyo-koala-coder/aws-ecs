# AWS 部署与清理操作手册

这是面向实际操作的 PowerShell 手顺。项目结构和各阶段设计见 [README](README.md)，首次实验的观察和故障恢复记录见 [lab.md](lab.md)。

## 当前开发环境

| 项目 | 值 |
| --- | --- |
| AWS 账户 / 区域 | `awsAccountId` / `region` |
| AWS CLI profile | `cicd-deploy` |
| GitHub 仓库 / 分支 |` https://github.com/tokyo-koala-coder/aws-ecs.git　`/ `master` |
| GitHub 连接 | `aws-ecs`，ARN 见 [开发环境配置](infra/config/dev.psd1) |
|--------------- CloudFormation 栈 | `java-ecs-demo-dev-pipeline`、`java-ecs-demo-dev-service` |


| 执行步骤 |

## 1. 配置 AWS CLI，准备CLI访问AWS云服务密钥

安装 AWS CLI v2。
在 IAM 中创建或复用部署专用 IAM 用户。
在该IAM用户下创建 Create access key 。密钥保存在本机 AWS 凭证文件中，仓库配置里只保存 profile 名称。[IAM 密钥设置](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-keys-admin-managed.html)

用 [configure-aws.ps1](infra/operations/configure-aws.ps1) 配置并验证身份。首次配置或更新本机 profile 时运行 `.\infra\operations\configure-aws.ps1 -Configure`，按提示输入访问密钥，默认区域填 `yourRegion`，输出格式填 `json`。已有 profile 时，按需运行 `.\infra\operations\configure-aws.ps1` 验证账户。STS 用于确认身份，后面的变更集会检查部署所需权限。

## 2. 准备 GitHub 仓库和连接

1. 把 `app/` 和 `infra/` 一起推送到目标 GitHub 分支，并保持它们位于仓库根目录。当前私有仓库及 `main` 已就绪。
2. [打开东京区 Connections](https://ap-northeast-1.console.aws.amazon.com/codesuite/settings/connections?region=ap-northeast-1)，核对 AWS 账户，选择 **Create connection → GitHub**。安装或选择属于目标 GitHub 账户的 **AWS Connector for GitHub**，授权访问目标私有仓库。已有状态为 `AVAILABLE` 的可用连接可以复用。[AWS 连接指南](https://docs.aws.amazon.com/dtconsole/latest/userguide/connections-create-github.html)
3. 将连接 ARN 填入 [infra/config/dev.psd1](infra/config/dev.psd1) 的 `Parameters.ConnectionArn`。同一文件还定义了 `Profile`、`Region`、`ExpectedAccount`、项目名、环境、仓库和分支。新环境可另建配置文件，部署时通过 `-ConfigPath` 指定。

从零准备仓库时，先在 GitHub 创建一个空的私有仓库，将仓库和分支填入环境配置，然后运行 [initialize-repository.ps1](scripts/initialize-repository.ps1)。脚本会初始化 Git、创建首次提交并推送到配置中的仓库和分支。当前工作区已配置 Git 和 `origin`，按日常流程提交并推送即可。

```powershell
.\scripts\initialize-repository.ps1
```

## 3. 本地验证

在本机测试或运行 Java 示例时，使用 JDK 17 和 Maven 3.9。

| 用途 | 脚本 | 调用 |
| --- | --- | --- |
| 运行测试并打包 JAR | [test-local.ps1](app/test-local.ps1) | `.\app\test-local.ps1` |
| 启动已打包的应用 | [run-local.ps1](app/run-local.ps1) | `.\app\run-local.ps1` |
| 从另一个窗口访问 `/` 和 `/health` | [check-local.ps1](app/check-local.ps1) | `.\app\check-local.ps1` |

只跑测试时执行第一条。试跑应用时先打包，再启动并检查。完成后在启动窗口按 Ctrl+C 停止服务。

可选的本地模板检查使用 `cfn-lint`，该工具依赖 Python。没有 Python 的电脑可以跳过这项检查，直接用第 4 步的 AWS CLI 调用 CloudFormation 验证模板。部署脚本使用 PowerShell 和 AWS CLI v2，内嵌的 Python Lambda 由 AWS 运行。

## 4. 用 IaC 创建或更新流水线

1. 运行 [preview-pipeline.ps1](infra/operations/preview-pipeline.ps1)（`.\infra\operations\preview-pipeline.ps1`）。脚本核对 AWS 账户、验证两份模板，再调用 [deploy.ps1](infra/deploy.ps1) 核对 GitHub 连接并预览流水线变更集。
2. 有变更时，复制预览输出的变更集 ARN，运行 [inspect-change-set.ps1](infra/operations/inspect-change-set.ps1)（`.\infra\operations\inspect-change-set.ps1 -ChangeSetArn '<变更集 ARN>'`），核对资源操作。若预览报告没有变更，到此结束。
3. 确认后，用同一个 ARN 运行 [apply-change-set.ps1](infra/operations/apply-change-set.ps1)（`.\infra\operations\apply-change-set.ps1 -ChangeSetArn '<变更集 ARN>'`）。脚本会执行这份变更集，等待并显示流水线栈的最终状态，预期为 `CREATE_COMPLETE` 或 `UPDATE_COMPLETE`。

如果希望直接按当前配置生成并执行一份新变更集，可使用 `.\infra\deploy.ps1 -Apply`。[AWS CLI 部署说明](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy.html)

## 5. 运行流水线并审批

从 CodePipeline 打开 `java-ecs-demo-dev`。首次建栈或推送 `main` 通常会自动触发执行。已有执行时，直接查看该次执行。需要手动启动时，点 **Release change** 或运行 [start-pipeline.ps1](infra/operations/start-pipeline.ps1)（`.\infra\operations\start-pipeline.ps1`）。

确认 GitHub 提交和 Maven 测试结果，然后用当前控制台登录身份在 **Approval → ApproveDeploy → Review → Approve** 点击批准。流水线随后推送镜像到 ECR，按镜像摘要部署 ECS，并创建或更新服务栈。

Java 源码、Dockerfile 和 `infra/service.yml` 的改动随 GitHub 分支进入流水线。`infra/pipeline.yml` 或部署参数的改动，回到第 4 步应用流水线栈。

## 6. 验证部署

在 CodePipeline 的执行详情中按阶段核对以下内容。

| 阶段 | 观察内容 |
| --- | --- |
| `Source` | 提交 ID 和预期的 GitHub `main` 提交一致。 |
| `StaticAnalysis` | `SourceHook` 和 `SkipStaticAnalysis` 均成功。Lambda 日志组为 `/aws/lambda/java-ecs-demo-dev-hook`。 |
| `Build` | 在 `MavenVerify` 的 **Details** 查看 CodeBuild 日志，确认 3 个测试通过且已生成 `app.jar`。 |
| `Approval` | Maven 成功后等待点击 **Approve**。批准后才会开始为本次执行构建和推送镜像。 |
| `Deploy` | `PushImageToECR` 成功后，在 ECR 核对新镜像，在 ECS 任务定义里核对镜像摘要。在 CloudFormation 服务栈的 **Events** 查看 ECS 服务和伸缩资源是否创建完成。 |

最后核对流水线执行为 `Succeeded`、服务栈为 `CREATE_COMPLETE` 或 `UPDATE_COMPLETE`、ECS 运行数达到期望值。伸缩范围预期为 1–2，CPU 目标为 70%。

运行 [verify-deployment.ps1](infra/operations/verify-deployment.ps1)（`.\infra\operations\verify-deployment.ps1`）查看流水线、服务栈、ECS、伸缩配置及日志。日志默认查最近一小时，可添加 `-LogSince 3h` 等参数调整范围。

在 ECS 服务的 **Tasks** 页查看任务健康状态，预期为 `HEALTHY`。CloudWatch 日志应显示 `Demo HTTP server listening on port 8080`。

## 遇到错误时

| 错误 | 处理步骤 |
| --- | --- |
| CLI `AccessDenied` | 先用 STS 核对 profile 对应的账户，再检查报错中列出的具体 IAM 操作。点击人工审批时报错时，检查当前控制台登录身份的 `codepipeline:PutApprovalResult`。 |
| Source 报 `No Branch [main] found` | 确认 GitHub 上的仓库和分支名称正确。在 [GitHub Installed Apps](https://github.com/settings/installations) 打开 **AWS Connector for GitHub → Configure → Repository access**，确认目标私有仓库已获授权，且 AWS 连接关联该 App 安装。保存后重试 Source。 |
| Deploy 的 `ScalingTarget` 报 `Unable to assume IAM role` | 在 IAM 核对 `AWSServiceRoleForApplicationAutoScaling_ECSService`。首次注册 ECS 伸缩目标时，AWS 会创建该服务关联角色，IAM 变更可能需要时间传播。角色就绪后按下方步骤恢复。 |

首次创建服务栈失败时，在 CloudFormation **Events** 查看首个失败资源。若 `java-ecs-demo-dev-service` 已进入 `ROLLBACK_COMPLETE`，先核对其中资源均已回滚，删除这个失败的服务栈记录，再到 CodePipeline 的 **Deploy → Retry failed actions** 重试。这样可以沿用同一次执行中的人工审批和已推送镜像。[AWS 服务关联角色说明](https://docs.aws.amazon.com/autoscaling/application/userguide/services-that-can-integrate-ecs.html) · [IAM 变更传播说明](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot.html) · [AWS 阶段重试说明](https://docs.aws.amazon.com/codepipeline/latest/userguide/stage-retry.html)

## 清理

**清理顺序是停止新部署 → 删除服务栈 → 删除流水线栈 → 清理保留的 S3 和 ECR。** Fargate 任务运行期间，以及其公有 IPv4、制品、镜像和日志存在期间，可能产生费用。

### 1. 暂停部署并记录保留资源

运行 [prepare-cleanup.ps1](infra/operations/prepare-cleanup.ps1)（`.\infra\operations\prepare-cleanup.ps1`）。核对输出的账号、区域、栈名，并记下 `ArtifactBucket` 和 `RepositoryName`，清理第 3 步会用到。确认暂停后，脚本会停用 `Deploy` 的入站转换。若仍有动作正在运行，等它们结束后重跑这一步。[AWS 阶段转换说明](https://docs.aws.amazon.com/codepipeline/latest/userguide/transitions.html)

### 2. 按顺序删除两个栈

记下保留资源名称后，运行 [remove-stacks.ps1](infra/operations/remove-stacks.ps1)（`.\infra\operations\remove-stacks.ps1`）。确认后，脚本先删除服务栈并等待完成，再删除流水线栈。脚本会跳过已经不存在的栈。删除失败时，到对应栈的 **Events** 查看 `DELETE_FAILED` 的原因。

### 3. 清除保留的制品和镜像

模板对 S3 制品桶和 ECR 仓库设置了 `Retain`，删除栈后仍会保留。确认资源仅用于本项目且可以永久删除后，将清理第 1 步记录的名称传给 [remove-retained-resources.ps1](infra/operations/remove-retained-resources.ps1)。脚本会确认两个栈已删除，并在删除资源前分别提示确认。[CloudFormation Retain 说明](https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-attribute-deletionpolicy.html)

```powershell
.\infra\operations\remove-retained-resources.ps1 -ArtifactBucket '<制品桶名>' -RepositoryName '<ECR 仓库名>'
```

如果桶的版本控制已启用或已暂停，到 S3 控制台清空对象版本和删除标记，然后在控制台删除桶。此时只传 `-RepositoryName` 运行脚本即可清理 ECR。中途失败后重试时，也可以只传仍需删除的资源名称。[S3 删除指南](https://docs.aws.amazon.com/AmazonS3/latest/userguide/delete-bucket.html)

### 4. 核对资源和账单

- 在 ECS 确认集群与服务已删除，任务已停止，任务使用的公有 IPv4 随任务释放。
- 在 S3 和 ECR 确认记录的桶与仓库已删除。如果以前替换过这些资源，检查替换时保留的旧桶和旧仓库。
- 在 CloudWatch 确认本项目的 Lambda、两个 CodeBuild、ECS 日志组以及伸缩告警已清理。需要留下排障证据时，先保存相关日志。
- 到 **Billing and Cost Management → Cost Explorer** 查看清理日期之后的 Fargate、公共 IPv4、S3、ECR、CloudWatch 和 CI/CD 用量。账单数据会延迟刷新，清理前已产生的费用仍会显示。[AWS 账单刷新说明](https://docs.aws.amazon.com/cost-management/latest/userguide/ce-what-is.html)
