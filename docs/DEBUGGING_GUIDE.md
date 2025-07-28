# CommandAI 终端卡死问题调试指南

## 🚨 紧急情况处理

如果终端完全无响应，请按以下顺序操作：

### 1. 立即恢复终端
```bash
# 在另一个终端窗口或通过 SSH 执行
cd /home/ts/code/commandAI
chmod +x emergency-fix.sh
./emergency-fix.sh
```

### 2. 重新加载配置
```bash
source ~/.zshrc
```

### 3. 验证终端正常
```bash
ls
pwd
echo "终端已恢复"
```

## 🔍 系统性调试步骤

### 步骤 1: 基础环境检查
```bash
cd /home/ts/code/commandAI
chmod +x debug-advanced.sh
./debug-advanced.sh > debug-output.log 2>&1
```

查看 `debug-output.log` 文件，重点关注：
- Python 脚本是否超时
- 模块语法是否有错误
- API 连接是否正常
- 配置文件是否正确解析

### 步骤 2: 隔离问题组件

#### 2.1 测试 Python 辅助脚本
```bash
HELPER="$HOME/.oh-my-zsh/custom/plugins/command-ai/bin/command-ai-helper"

# 测试基本功能
timeout 5s python3 "$HELPER" --help

# 测试各个功能模块
timeout 3s python3 "$HELPER" cache --cache-action stats
timeout 5s python3 "$HELPER" translate --query "test"
timeout 3s python3 "$HELPER" correct --query "test" --error "error"
```

#### 2.2 测试 Zsh 模块
```bash
PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins/command-ai"

# 检查语法
for module in "$PLUGIN_DIR/modules"/*.zsh; do
    echo "检查 $(basename "$module"):"
    zsh -n "$module" || echo "语法错误"
done

# 单独加载测试
zsh -c "source '$PLUGIN_DIR/modules/correction.zsh'; echo '纠错模块加载成功'"
```

#### 2.3 测试配置文件
```bash
python3 -c "
import configparser
config = configparser.ConfigParser()
try:
    config.read('$HOME/.config/command-ai/config.ini')
    print('配置文件解析成功')
    print('节数量:', len(config.sections()))
except Exception as e:
    print('配置文件错误:', e)
"
```

### 步骤 3: 网络和 API 测试
```bash
# 测试网络连接
timeout 5s curl -s https://api.moonshot.cn/v1/models

# 测试 API 调用
API_KEY=$(grep '^key' ~/.config/command-ai/config.ini | cut -d'=' -f2 | tr -d ' ')
timeout 10s curl -s -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"moonshot-v1-auto","messages":[{"role":"user","content":"test"}]}' \
    https://api.moonshot.cn/v1/chat/completions
```

## 🔧 常见问题和解决方案

### 问题 1: Python 脚本超时
**症状**: 所有涉及 AI 的功能都超时
**原因**: 网络问题、API 配置错误、或 API 服务异常
**解决方案**:
```bash
# 检查网络
ping -c 3 api.moonshot.cn

# 验证 API Key
echo "API Key: $(grep '^key' ~/.config/command-ai/config.ini | cut -d'=' -f2)"

# 使用测试配置
cp ~/.config/command-ai/config-safe.ini ~/.config/command-ai/config.ini
```

### 问题 2: precmd 钩子卡死
**症状**: 每次命令执行后终端卡住
**原因**: 自动纠错功能触发 AI 调用
**解决方案**:
```bash
# 禁用自动纠错
sed -i 's/auto_trigger = true/auto_trigger = false/' ~/.config/command-ai/config.ini
sed -i 's/auto_correction = true/auto_correction = false/' ~/.config/command-ai/config.ini
```

### 问题 3: Tab 补全卡死
**症状**: 按 Tab 键后终端无响应
**原因**: 智能补全功能调用 AI 服务
**解决方案**:
```bash
# 禁用智能补全
sed -i 's/smart_completion = true/smart_completion = false/' ~/.config/command-ai/config.ini
sed -i 's/enabled = true/enabled = false/' ~/.config/command-ai/config.ini
```

### 问题 4: 模块加载错误
**症状**: 插件加载时报语法错误
**原因**: 文件损坏或权限问题
**解决方案**:
```bash
# 重新安装插件
cd /home/ts/code/commandAI
./install-safe.sh

# 检查权限
chmod +x ~/.oh-my-zsh/custom/plugins/command-ai/bin/command-ai-helper
```

## 📊 性能优化建议

### 1. 配置优化
```ini
[advanced]
request_timeout = 5          # 减少超时时间
max_retries = 1             # 减少重试次数
debug_mode = false          # 关闭调试模式

[features]
auto_correction = false     # 禁用自动纠错
smart_completion = false    # 禁用智能补全
```

### 2. 缓存优化
```bash
# 清理缓存
rm -rf ~/.cache/command-ai/*

# 重建缓存
python3 ~/.oh-my-zsh/custom/plugins/command-ai/bin/command-ai-helper cache --cache-action clear
```

### 3. 网络优化
```bash
# 设置代理（如果需要）
export HTTP_PROXY=http://proxy.example.com:8080
export HTTPS_PROXY=http://proxy.example.com:8080

# 或者使用国内镜像（如果有）
```

## 🧪 安全测试流程

### 1. 最小功能测试
```bash
# 只启用基本功能
cat > ~/.config/command-ai/config-minimal.ini << 'EOF'
[api]
key = your_api_key_here
url = https://api.moonshot.cn/v1
model = moonshot-v1-auto

[features]
auto_correction = false
smart_completion = false
natural_language = true
command_cache = false
security_check = false
EOF

# 使用最小配置测试
export COMMAND_AI_CONFIG=~/.config/command-ai/config-minimal.ini
ai "list files"
```

### 2. 逐步启用功能
```bash
# 1. 先启用缓存
sed -i 's/command_cache = false/command_cache = true/' ~/.config/command-ai/config-minimal.ini

# 2. 再启用安全检查
sed -i 's/security_check = false/security_check = true/' ~/.config/command-ai/config-minimal.ini

# 3. 最后启用其他功能（谨慎）
# sed -i 's/auto_correction = false/auto_correction = true/' ~/.config/command-ai/config-minimal.ini
```

## 📞 获取帮助

如果以上步骤都无法解决问题，请：

1. 收集调试信息：
   ```bash
   ./debug-advanced.sh > full-debug.log 2>&1
   ```

2. 检查系统日志：
   ```bash
   tail -50 /var/log/syslog | grep -i error
   ```

3. 提供环境信息：
   ```bash
   echo "OS: $(uname -a)"
   echo "Zsh: $(zsh --version)"
   echo "Python: $(python3 --version)"
   echo "Shell: $SHELL"
   ```

记住：**安全第一**，如果插件导致终端不稳定，建议先禁用有问题的功能，只使用稳定的核心功能。
