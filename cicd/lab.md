# 首次 CI/CD 实验记录

2026-11-22 在 AWS 东京区 `ap-northeast-1` 完成首次端到端实验。可重复执行的命令见 [操作手册](manual.md)，模板和目录说明见 [README](README.md)。

## 实验目标

- 让 CodePipeline 从 GitHub 私有仓库的 `main` 读取指定提交。
- 让 CodeBuild 完成 Java 测试和打包，人工批准后再推送 ARM64 镜像并部署 ECS。
- 核对 ECS 任务健康状态、CloudWatch 启动日志，以及自动伸缩策略。

## 实验对象

| 项目 | 值 |
| --- | --- |
| AWS 账户 / 区域 | `572535616215` / `ap-northeast-1` |
| GitHub 源码 | `mystylezfzjp-eng/cicd-java-ecs-demo` 的 `main`，提交 `724abf7` |
| CodePipeline | `java-ecs-demo-dev` |
| 执行 ID | `c68b9f87-5e71-40c0-8b96-ccfa0edd5193` |
| CloudFormation 栈 | `java-ecs-demo-dev-pipeline`、`java-ecs-demo-dev-service` |

## 执行过程

1. **本地验证。** Maven 的 3 个 JUnit 测试通过，生成可执行 JAR。ARM64 容器在 0.25 vCPU、512 MiB 限制下响应了 `/` 和 `/health`。两份 CloudFormation 模板通过本地 `cfn-lint` 和 AWS `ValidateTemplate`。
2. **创建流水线。** 用 `cicd-deploy` 验证目标账户，确认 GitHub 连接 `github-cicd-demo` 为 `AVAILABLE`。CloudFormation 变更集预览包含 25 项新增资源，执行后创建流水线栈。
3. **拉取源码并构建。** 首次 Source 动作报 `No Branch [main] found`。通过 GitHub API 核对，私有仓库的 `main` 存在，AWS 中配置的仓库名和分支也一致。排查重点是连接所用 GitHub App 的私有仓库授权，随后重试源码动作成功。两个 Lambda 占位动作及 Maven 构建均通过。
4. **审批并推送镜像。** 在控制台批准 `ApproveDeploy`。CodeBuild 将测试阶段交付的 JAR 构建为 ARM64 镜像并推送至 ECR。部署阶段根据镜像摘要发起服务栈创建。
5. **恢复首次 ECS 部署。** `ScalingTarget` 报 `Unable to assume IAM role`，服务栈进入 `ROLLBACK_COMPLETE`。核对 AWS 事件发现，ECS 自动伸缩的服务关联角色约在报错前 1 秒创建，IAM 传播延迟是最可能的原因。确认角色及其信任关系已就绪、栈内资源已回滚后，删除失败的服务栈记录，只重试 `DeployFargateService`。重试沿用本次审批和已推送的镜像。 [AWS IAM 传播说明](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot.html) · [CodePipeline 重试说明](https://docs.aws.amazon.com/codepipeline/latest/userguide/stage-retry.html)

## 验证结果

| 观察位置 | 实际结果 |
| --- | --- |
| CodePipeline 执行 | `Succeeded`。 |
| CloudFormation 服务栈 | `CREATE_COMPLETE`。任务定义、服务、伸缩目标和 CPU 策略均创建完成。 |
| ECS 服务和任务 | 服务达到稳定状态。期望 1 个任务，实际运行 1 个，容器健康状态为 `HEALTHY`。 |
| CloudWatch Logs | 出现 `Demo HTTP server listening on port 8080`。 |
| Application Auto Scaling | 最小 1，最大 2，`ECSServiceAverageCPUUtilization` 目标为 70%。 |

自动伸缩验证覆盖配置和资源创建，实际触发扩容与缩容属于后续负载实验。实验结束时保留了已部署资源。完成演示后按 [操作手册](manual.md) 的「清理」一节删除栈及保留的 S3 和 ECR。
