#!/bin/bash

# CommandAI 安全安装脚本
# 这个版本会创建一个更安全的配置，避免终端卡死问题

set -e

echo "🔧 CommandAI 安全安装脚本"
echo "========================="

# 检查 Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "❌ 未检测到 Oh My Zsh，请先安装 Oh My Zsh"
    exit 1
fi

# 创建插件目录
PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins/command-ai"
echo "📁 创建插件目录: $PLUGIN_DIR"
mkdir -p "$PLUGIN_DIR"/{bin,modules,completions}

# 复制文件
echo "📋 复制插件文件..."
cp command-ai.plugin.zsh "$PLUGIN_DIR/"
cp -r bin/* "$PLUGIN_DIR/bin/"
cp -r modules/* "$PLUGIN_DIR/modules/"
cp -r completions/* "$PLUGIN_DIR/completions/"

# 设置执行权限
chmod +x "$PLUGIN_DIR/bin/command-ai-helper"

# 创建配置目录
CONFIG_DIR="$HOME/.config/command-ai"
echo "⚙️  创建配置目录: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# 创建安全配置文件
echo "📝 创建安全配置文件..."
cat > "$CONFIG_DIR/config.ini" << 'EOF'
# CommandAI 安全配置文件
# 此配置禁用了可能导致终端卡死的功能

[api]
key = your_api_key_here
url = https://api.moonshot.cn/v1
model = moonshot-v1-auto

[features]
auto_correction = false         # 禁用自动纠错
smart_completion = false        # 禁用智能补全
natural_language = true         # 保留自然语言转换
command_cache = true           # 保留缓存
security_check = true          # 保留安全检查

[correction]
auto_trigger = false           # 禁用自动触发
show_suggestions = true
max_suggestions = 3

[completion]
enabled = false               # 禁用智能补全
timeout = 3
max_suggestions = 10
async_mode = true

[natural_language]
enabled = true
prefix = "#"
auto_execute = false
show_explanation = true

[security]
enabled = true
blacklist_file = ~/.config/command-ai/blacklist.txt
danger_confirmation = true
dry_run_preference = true
risk_threshold = medium

[cache]
enabled = true
max_entries = 1000
ttl_days = 30
auto_cleanup = true
feedback_learning = true

[ui]
colors = true
progress_bar = true
confirmation_prompt = true
verbose_output = false

[logging]
enabled = false
level = info
file = ~/.cache/command-ai/command-ai.log
max_size_mb = 10
backup_count = 3

[advanced]
request_timeout = 10
max_retries = 2
parallel_requests = false
debug_mode = false
api_rate_limit = 60
cache_compression = false
memory_limit_mb = 100
temp_dir = /tmp
fallback_mode = true

[shortcuts]
smart_completion = "^I"      # Tab 键（已禁用）
alternative_completion = "^@" # Ctrl+Space（已禁用）
manual_completion = "^X^A"   # Ctrl+X Ctrl+A
fix_command = "^X^F"        # Ctrl+X Ctrl+F
nl_translate = "^X^N"       # Ctrl+X Ctrl+N

[prompts]
# 自定义提示词（可选）
correction_system_prompt = 你是一个专业的命令行助手。分析失败命令并提供修复建议。要求：1.只返回修正后的命令 2.危险操作加[DANGER]标签 3.优先使用安全参数 4.保持原始意图
translation_system_prompt = 你是一个命令行翻译助手。将自然语言转换为shell命令。要求：1.只返回命令 2.危险操作加[DANGER]标签 3.使用常见Unix命令 4.考虑跨平台兼容性
completion_system_prompt = 你是一个命令行补全助手。提供相关补全建议，返回JSON格式。要求：1.最多10个建议 2.按相关性排序 3.包含描述 4.简洁明了
EOF

# 创建缓存目录
mkdir -p "$HOME/.cache/command-ai"

# 创建黑名单文件
cat > "$CONFIG_DIR/blacklist.txt" << 'EOF'
# CommandAI 命令黑名单
# 这些命令将被禁止生成和执行

rm -rf /
rm -rf /*
mkfs
dd if=
format
fdisk
parted
EOF

echo "✅ 安全安装完成！"
echo ""
echo "📋 接下来的步骤："
echo "1. 编辑 ~/.zshrc，在 plugins 列表中添加 command-ai"
echo "   例如：plugins=(git command-ai)"
echo "2. 编辑 $CONFIG_DIR/config.ini 设置你的 API Key"
echo "3. 运行 source ~/.zshrc 重新加载配置"
echo "4. 测试：ai \"列出当前目录文件\""
echo ""
echo "⚠️  注意：此安全版本默认禁用了自动纠错和智能补全功能"
echo "   如需启用，请编辑配置文件中的相应选项"
echo ""
echo "🔧 调试模式："
echo "   如果遇到问题，可以设置 export COMMAND_AI_DEBUG=1"
echo "   然后查看详细日志输出"
