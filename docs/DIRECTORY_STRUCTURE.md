# CommandAI 项目目录结构说明

本文档详细说明了 CommandAI 项目中每个文件和目录的作用，帮助你更好地理解项目结构。

## 根目录

-   `command-ai.plugin.zsh`: Zsh 插件的**主入口文件**。它负责加载所有模块和初始化插件。
-   `command-ai-passive.plugin.zsh`: Zsh 插件的**被动模式**版本。此版本仅提供基础功能，性能开销更小，适用于不希望频繁与 AI 交互的用户。
-   `completions/`: 存放 Zsh 的**原生补全脚本**。
    -   `_command-ai`: 为 `ai` 命令提供基础的子命令补全（如 `fix`, `help` 等）。
-   `README.md`: 项目的主要文档，包含项目介绍、功能、安装指南和使用示例。*(此文件在整理后已被移入 `docs` 目录，但为保持完整性在此提及)*

## `bin/` - 可执行文件

存放项目所需的可执行脚本，主要是核心功能的 Python 辅助脚本。

-   `command-ai-helper`: Python 编写的**核心辅助脚本**。负责与 AI API 交互、处理缓存、执行命令分析等核心逻辑。Zsh 模块通过调用此脚本来获得 AI 能力。
-   `__pycache__/`: Python 解释器自动生成的缓存文件，用于加速模块加载。

## `config/` - 配置文件

存放所有与配置相关的文件。

-   `config.example.ini`: **配置模板文件**。包含了所有可用的配置选项及其详细说明。用户应复制此文件到 `~/.config/command-ai/config.ini` 并进行个性化设置。
-   `config-debug.ini`: **调试专用配置文件**。此配置开启了详细的日志记录和调试模式，方便开发者排查问题。
-   `custom-prompt-example.ini`: **自定义 Prompt 示例文件**。展示了如何覆盖默认的 AI 提示词，以实现更高级的定制。

## `docs/` - 文档

存放项目的所有相关文档。

-   `DIRECTORY_STRUCTURE.md`: **本文档**，提供项目目录结构的详细说明。
-   `CUSTOM_PROMPTS_GUIDE.md`: **自定义 Prompt 指南**。详细介绍了如何修改和定制与 AI 交互的提示词。
-   `DEBUGGING_GUIDE.md`: **调试指南**。提供了如何对 CommandAI 进行问题排查和调试的详细步骤。
-   `PROJECT_SUMMARY.md`: **项目摘要**，提供了项目的高层概述。

## `modules/` - Zsh 模块

存放实现各项功能的独立的 Zsh 脚本模块。主插件文件会按需加载这些模块。

-   `cache.zsh`: **缓存模块**。负责命令和 AI 结果的缓存，提高响应速度。
-   `completion.zsh`: **智能补全模块**。实现了基于 AI 的命令参数和选项的智能补全。
-   `correction.zsh`: **命令纠错模块**。当用户输入错误命令时，提供修正建议。
-   `nl2cmd.zsh`: **自然语言转命令模块**。实现了将自然语言（以 `#` 开头）转换为 Shell 命令的核心功能。
-   `security.zsh`: **安全检查模块**。在执行 AI 生成的命令前进行风险分析，并对高风险命令进行提示。

## `scripts/` - 工具脚本

存放用于项目管理、安装、调试的辅助 Shell 脚本。

-   `install.sh`: **全功能安装脚本**。会自动处理依赖检查、文件复制、配置生成和 `.zshrc` 修改。
-   `install-safe.sh`: **安全安装脚本**。只复制必要的文件，大部分配置需要用户手动完成，提供了一个更可控的安装过程。
-   `debug-advanced.sh`: **高级调试脚本**。用于执行更复杂的调试任务。
-   `demo.sh`: **功能演示脚本**。用于快速展示 CommandAI 的各项核心功能。
-   `emergency-fix.sh`: **紧急修复脚本**。在出现严重问题时，用于恢复或禁用插件。
-   `quick-test.sh`: **快速测试脚本**。用于运行一套基本的测试，以验证核心功能是否正常。

## `tool/` - 开发者工具

存放开发过程中使用的一些辅助工具。

-   `getModelList.py`: 用于获取 AI 服务提供商支持的**模型列表**的 Python 脚本。
