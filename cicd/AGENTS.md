# AGENTS.md

## 项目背景

- 本工程使用 CloudFormation YAML 管理 AWS 基础设施，通过 CodePipeline 将 Java 17 示例部署到 ECS Fargate。
- `app/` 存放 Java 源码、测试、Maven 配置和 Dockerfile。`infra/` 存放 CloudFormation 模板和 CodeBuild 配置。

## 开发约定

- 本地开发环境使用 Windows PowerShell。提供本地命令时，优先使用 PowerShell 兼容语法。
- PowerShell 脚本、模块和数据文件（`.ps1`、`.psm1`、`.psd1`）使用带 BOM 的 UTF-8 保存，以兼容 Windows PowerShell 5.1。支持 EditorConfig 的编辑器可以读取仓库的 `.editorconfig` 来应用此设置。
- 将 AWS 账户、区域和环境差异放在配置中。IAM 权限遵循最小权限原则，避免将凭证和其他密钥写入仓库或日志。
- 修改基础设施或流水线时，优先使用项目已有的格式检查、测试和计划预览验证变更。执行部署时核对目标账户、区域和环境。
- CodeBuild 从 Git 仓库根目录执行，构建配置位于 `cicd/infra/buildspec/`，Maven 输出 `cicd/app/target/app.jar`。本文件所在的 `cicd/` 是项目目录。调整目录或制品路径时，同步更新流水线、构建配置及相关文档。
- 在 `infra/config/` 保存各环境的流水线参数，通过 `infra/deploy.ps1` 预览和部署流水线栈。
- 本地应用脚本放在 `app/`，AWS 运维脚本放在 `infra/operations/`，仓库初始化脚本放在 `scripts/`。在 `manual.md` 链接可执行脚本并说明使用条件。AWS 运维脚本各自读取环境配置，无需预先加载会话变量。
- 独立注释块与上一段代码之间留一个空行。构建脚本中不同用途的命令也用空行分段。

## 记录变更

- 在 `AGENTS.md` 更新长期有效的项目约定。每次项目变更完成时，在 `CHANGELOG.md` 记录日期、变更内容和验证结果。如果 AWS 部署或端到端验证尚未执行，明确记录。
- 项目结构和架构说明维护在 `README.md`，本地运行、部署、验证和清理的步骤维护在 `manual.md`，实验过程与实际观察维护在 `lab.md`。
