# 变更记录

## 2026-11-23

- 将手册中的本地测试、仓库初始化、AWS 身份配置、流水线预览与执行、部署验证和清理命令提取为独立的 PowerShell 脚本。手册按使用场景标明步骤入口，并保留 GitHub 授权和人工审批等控制台操作。已通过 Windows PowerShell 5.1 语法检查、文档链接检查、AWS CLI 模拟流程、3 个 JUnit 测试及本地 HTTP 双端点验证。未执行实际 AWS 部署、清理或端到端验证。
- 在操作手册中区分 Java 本地工具、部署工具和可选的 Python 模板检查，并修正 `-Apply` 示例的脚本路径。
- 在代码、构建配置和模板的独立注释前补空行，并将镜像构建命令按用途分段。已核对非空行一致，CloudFormation 静态检查以及 Bash、Python 和 PowerShell 语法检查通过。

## 2026-11-22

- 按用途拆分文档。README 说明项目结构和架构，`manual.md` 保存部署、验证和清理手顺，`lab.md` 记录首次端到端实验及故障恢复。已核对文档链接、16 个文件的目录树和手册中的 15 段 PowerShell 示例。
- 在 README 补充工程目录树、主要文件用途，以及流水线模板、服务模板和 JAR 制品在部署中的关系。已核对目录树与工作区文件一致。
- 为应用、Dockerfile、CloudFormation、CodeBuild 和部署脚本补充注释。README 增加从空仓库起步的命令、各阶段的观察点，以及按顺序删除服务栈、流水线栈和保留的 S3/ECR 并核对账单的步骤。3 个 JUnit 测试、两份模板的本地和 AWS 验证、文档 PowerShell 语法检查均通过。AWS 清理命令未执行。
- 将 README 整理为从 AWS CLI、GitHub 授权、IaC 变更集到审批、验证、故障恢复和清理的操作手册。已检查 PowerShell 代码块语法和本地链接，并以 AWS CLI 复核流水线、ECS 服务及伸缩配置。
- 在东京区完成流水线首次端到端部署。首次创建 ECS 伸缩目标时，服务关联角色刚创建，AWS 返回角色无法承担。确认角色已就绪后，删除已回滚的服务栈记录并重试失败动作。流水线执行成功，Fargate 任务健康，已核实伸缩范围 1–2 和平均 CPU 目标 70%。README 已记录恢复步骤。
- 配置东京区的 GitHub 连接 `github-cicd-demo`，通过 AWS CLI 确认状态为 `AVAILABLE`。已生成并核对流水线变更集，预览包含 25 项新增资源，尚未执行。
- 将开发环境的目标 AWS 账户切换为 `572535616215`，使用 `cicd-deploy` profile。STS 账户核对和两份模板的 AWS `ValidateTemplate` 均通过。东京区暂无 GitHub 连接，尚未部署。
- 新增 PowerShell 流水线部署脚本和开发环境参数文件。已验证模板静态检查，并用模拟 AWS CLI 验证预览、应用、账户不匹配和连接未授权时的行为。当前仍缺少可用的 GitHub Connection ARN，尚未在 AWS 执行部署。
- 更新 README 的控制台操作说明，明确由当前登录身份点击人工审批，随后由流水线自动部署。已核对模板中的审批动作和部署角色配置。
- 新增项目变更记录，并在 `AGENTS.md` 写入目录、构建路径和记录约定。
- 将 Java 工程和 Dockerfile 移到 `app/`，将 CodeBuild 配置移到 `infra/buildspec/`，同步更新流水线制品路径、README 和忽略规则。3 个 JUnit 测试、两份模板的 `cfn-lint` 检查和模拟的制品交接均通过。尚未部署到 AWS。
- 初始化 Java 17 示例与五阶段 CodePipeline，添加 ECR、ECS Fargate 和 CPU 目标跟踪伸缩。3 个 JUnit 测试、模板静态检查和本地 ARM64 容器健康检查通过。AWS 端到端验证待配置 GitHub 仓库与连接，以及具备部署权限的 AWS CLI profile。
