# GitHub → CodePipeline → ECS Fargate

这个示例使用 CloudFormation YAML、AWS CodePipeline 和 Java 17。Java HTTP 服务提供 `/` 和 `/health`。

| 文档 | 内容 |
| --- | --- |
| [manual.md](manual.md) | 从零部署、日常发布、验证和 AWS 清理的操作命令。 |
| [lab.md](lab.md) | 首次实验的执行过程、故障恢复和实际验证结果。 |
| [CHANGELOG.md](CHANGELOG.md) | 项目改动与验证历史。 |
| [AGENTS.md](AGENTS.md) | 开发、部署和维护文档的约定。 |

## 工程结构

```text
.
├── app/
│   ├── pom.xml                        # Java 17、JUnit 和可执行 JAR 打包
│   ├── Dockerfile                     # 将已测试的 JAR 放入 Corretto 容器
│   ├── test-local.ps1                  # 运行 Maven 验证并打包
│   ├── run-local.ps1                   # 启动本地 Java HTTP 服务
│   ├── check-local.ps1                 # 请求本地服务的两个端点
│   └── src/
│       ├── main/java/demo/App.java    # HTTP 服务，提供 / 和 /health
│       └── test/java/demo/AppTest.java # JUnit HTTP 测试
├── infra/
│   ├── pipeline.yml                   # 流水线栈，包含 CodeBuild、ECR、S3、ECS 集群和网络
│   ├── service.yml                    # 服务栈，包含 Fargate 任务定义、服务和自动伸缩
│   ├── deploy.ps1                     # 核对环境并预览或部署流水线栈
│   ├── config/
│   │   └── dev.psd1                    # AWS profile、账户、区域、仓库、分支和连接 ARN
│   ├── operations/
│   │   ├── environment.ps1             # 环境配置与 AWS CLI 调用
│   │   ├── configure-aws.ps1           # 初始化或核对 AWS CLI 身份
│   │   ├── preview-pipeline.ps1        # 验证模板并预览流水线变更
│   │   ├── inspect-change-set.ps1      # 查看变更集的资源操作
│   │   ├── apply-change-set.ps1        # 执行指定变更集并等待完成
│   │   ├── start-pipeline.ps1          # 手动启动流水线
│   │   ├── verify-deployment.ps1       # 查看执行、服务、伸缩和日志
│   │   ├── cleanup-state.ps1           # 读取栈和部署阶段状态
│   │   ├── prepare-cleanup.ps1         # 记录保留资源并暂停部署
│   │   ├── remove-stacks.ps1           # 按顺序删除两个栈
│   │   └── remove-retained-resources.ps1 # 删除保留的 S3 制品桶或 ECR 仓库
│   └── buildspec/
│       ├── test.yml                   # Maven 测试和 JAR 制品输出
│       └── image.yml                  # 构建 ARM64 镜像、推送 ECR 并准备服务部署制品
├── scripts/
│   └── initialize-repository.ps1       # 初始化 Git、提交并推送到配置中的仓库
├── .gitignore                         # 排除本地构建产物和工具环境
├── AGENTS.md                          # 项目开发约定
├── CHANGELOG.md                       # 变更和验证记录
├── README.md                          # 项目结构、架构和流水线阶段
├── manual.md                          # 部署、日常操作和资源清理
└── lab.md                             # 实验过程、故障恢复和验证证据
```

首次建栈时，[部署脚本](infra/deploy.ps1) 读取 [环境参数](infra/config/dev.psd1)，部署 [流水线模板](infra/pipeline.yml)。每次发布时，Maven 生成的 `app/target/app.jar` 通过流水线传给镜像构建。审批通过后，流水线从同一次源码提交取得 [服务模板](infra/service.yml)，使用推送到 ECR 的镜像摘要部署。Lambda 扩展点使用流水线模板中的内嵌 Python。

## 流水线阶段

| 阶段 | 动作 |
| --- | --- |
| 1. Source | CodeConnections 监听指定 GitHub 分支，检出提交并生成 ZIP 制品。手动启动会使用该分支最新提交，后续动作使用同一次执行的源码。 |
| 2. StaticAnalysis | 首先运行预留的 `SourceHook` Lambda 动作，然后运行直接返回成功的静态检查占位动作。 |
| 3. Build | CodeBuild 执行 `mvn -B -ntp -f app/pom.xml clean verify`，运行 JUnit 测试并将应用和 Maven 运行时依赖打包为 `app.jar`。 |
| 4. Approval | 在 CodePipeline 控制台人工批准。 |
| 5. Deploy | CodeBuild 用阶段 3 的 JAR 构建 ARM64 镜像并推送到 ECR。CloudFormation 使用镜像摘要创建或更新 ECS 任务定义及服务。 |

第一阶段只允许 Source 动作，因此 Lambda 放在紧接 GitHub 源动作的位置。以后可以在 [流水线模板](infra/pipeline.yml) 的 `PipelineHook` 中添加自定义逻辑。当前 Lambda 接收流水线制品元数据并报告成功，实际源码由已授权的 CodeConnections 获取。[AWS 的阶段约束](https://docs.aws.amazon.com/codepipeline/latest/userguide/pipeline-requirements.html)

首次批准前只创建流水线、ECR、日志、网络和 ECS 集群。首次部署会创建独立的服务栈。任务采用 Linux ARM64 Fargate 按需的最小规格（0.25 vCPU、512 MiB），期望任务数自动伸缩范围为 1–2，平均 CPU 目标为 70%。滚动发布可临时运行额外的任务。示例使用一个公有子网，任务公有 IPv4 用于出站拉镜像和写日志，安全组没有入站规则，也没有负载均衡器。可以通过 ECS 健康状态和 CloudWatch Logs 验证运行结果。Fargate、IPv4、构建、存储和日志可能产生费用。[Fargate 定价](https://aws.amazon.com/fargate/pricing/)

准备运行示例时，按 [操作手册](manual.md) 配置和部署。演示结束后按手册清理 AWS 资源，包括模板保留的 S3 制品桶和 ECR 仓库。
