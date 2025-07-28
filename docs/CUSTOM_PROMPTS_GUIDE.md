# CommandAI 自定义提示词使用指南

## 概述

CommandAI 支持自定义 AI 提示词，让你可以根据个人需求和使用习惯调整 AI 的行为。这个功能让你能够：

- 调整 AI 的响应风格（正式/友好/技术性）
- 定制安全策略和风险评估标准
- 优化特定场景下的命令建议
- 支持多语言和特定领域的命令

## 快速开始

### 1. 查看当前配置

```bash
# 查看默认配置
cat config.example.ini

# 查看自定义示例
cat custom-prompt-example.ini
```

### 2. 创建自定义配置

```bash
# 复制示例配置
cp custom-prompt-example.ini ~/.config/command-ai/config.ini

# 或者编辑现有配置
vim ~/.config/command-ai/config.ini
```

### 3. 测试自定义配置

```bash
# 重新加载配置
source ~/.zshrc

# 测试命令纠错
ai fix

# 测试自然语言转换
ai "列出所有 Python 文件"

# 测试智能补全
git <Tab>
```

## 提示词类型详解

### 1. 命令纠错提示词 (correction_system_prompt)

**用途**: 控制 `ai fix` 和自动纠错功能的行为

**默认行为**:
- 分析失败命令和错误信息
- 提供准确的修正建议
- 标记危险操作
- 优先推荐安全参数

**自定义示例**:
```ini
correction_system_prompt = 你是一位经验丰富的 DevOps 工程师。当命令执行失败时，请：1) 详细分析错误原因 2) 提供多种解决方案 3) 解释每个解决方案的优缺点 4) 对于生产环境操作，务必添加 [DANGER] 标记并建议在测试环境先验证
```

### 2. 自然语言转命令提示词 (translation_system_prompt)

**用途**: 控制自然语言到 shell 命令的转换

**默认行为**:
- 理解中英文描述
- 生成标准 Unix/Linux 命令
- 考虑跨平台兼容性
- 标记危险操作

**自定义示例**:
```ini
translation_system_prompt = 你是一个专精于云原生技术的命令行专家。将自然语言转换为命令时：1) 优先使用现代工具（如 exa 代替 ls，bat 代替 cat）2) 支持 Kubernetes、Docker 等云原生工具 3) 生成的命令要包含有用的参数和选项 4) 对于集群操作必须添加 [DANGER] 标记
```

### 3. 智能补全提示词 (completion_system_prompt)

**用途**: 控制 Tab 键智能补全的行为

**默认行为**:
- 基于上下文提供补全建议
- 返回 JSON 格式的建议列表
- 包含命令、参数、文件名等
- 提供简洁的描述

**自定义示例**:
```ini
completion_system_prompt = 你是一个高级命令行补全引擎，专注于提高开发者效率。提供补全建议时：1) 优先显示最常用的选项 2) 包含实用的参数组合 3) 为复杂命令提供使用示例 4) 支持现代开发工具链（Git、Docker、npm 等）5) 描述要包含使用场景
```

## 高级自定义技巧

### 1. 角色定位

为 AI 设定明确的角色身份：
```ini
correction_system_prompt = 你是一位有 10 年经验的 Linux 系统管理员...
translation_system_prompt = 你是一个专精于数据科学的命令行专家...
completion_system_prompt = 你是一个专注于 Web 开发的终端效率专家...
```

### 2. 安全策略定制

根据你的安全需求调整风险评估：
```ini
# 严格模式 - 对所有系统级操作都标记为危险
correction_system_prompt = ...对于任何涉及 sudo、rm、chmod、chown 的操作都必须添加 [DANGER] 标记...

# 宽松模式 - 只对真正危险的操作标记
correction_system_prompt = ...只对可能造成数据丢失或系统损坏的操作添加 [DANGER] 标记...
```

### 3. 领域专业化

针对特定技术栈优化：
```ini
# 云原生专用
translation_system_prompt = ...优先使用 kubectl、helm、docker 等云原生工具...

# 数据科学专用  
translation_system_prompt = ...熟悉 pandas、numpy、jupyter 等数据科学工具的命令行接口...

# 前端开发专用
completion_system_prompt = ...重点支持 npm、yarn、webpack、vite 等前端工具...
```

### 4. 多语言支持

```ini
translation_system_prompt = 你是一个多语言命令行助手，能够理解中文、英文、日文的自然语言描述，并转换为准确的 shell 命令...
```

## 测试和验证

### 1. 功能测试

```bash
# 测试命令纠错
echo "wrong_command" | bash
ai fix

# 测试自然语言转换
ai "查找大于 100MB 的文件"
ai "启动一个 Python HTTP 服务器"

# 测试智能补全
git <Tab>
docker <Tab>
```

### 2. 配置验证

```bash
# 检查配置文件格式
python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('~/.config/command-ai/config.ini')
print('配置文件格式正确')
"
```

### 3. 性能测试

```bash
# 测试响应时间
time ai "列出当前目录的文件"
```

## 故障排除

### 常见问题

1. **配置文件格式错误**
   ```bash
   # 检查语法
   python3 -c "import configparser; configparser.ConfigParser().read('config.ini')"
   ```

2. **提示词过长导致 API 调用失败**
   - 保持提示词简洁，建议不超过 500 字符
   - 避免重复的指令

3. **AI 响应不符合预期**
   - 检查提示词的逻辑性和清晰度
   - 测试不同场景下的表现
   - 逐步调整和优化

### 调试技巧

```bash
# 查看详细日志
export COMMAND_AI_DEBUG=1
ai "测试命令"

# 重置为默认配置
mv ~/.config/command-ai/config.ini ~/.config/command-ai/config.ini.backup
cp config.example.ini ~/.config/command-ai/config.ini
```

## 最佳实践总结

1. **渐进式调整**: 从默认配置开始，逐步调整单个提示词
2. **保持一致性**: 确保不同提示词之间的风格和要求一致
3. **安全第一**: 始终强调安全性，特别是危险命令的处理
4. **测试验证**: 每次修改后都要测试各种使用场景
5. **备份配置**: 保留工作良好的配置版本
6. **文档记录**: 记录自定义的原因和预期效果

通过合理的自定义配置，CommandAI 可以更好地适应你的工作流程和使用习惯，提供更加个性化和高效的命令行体验。
