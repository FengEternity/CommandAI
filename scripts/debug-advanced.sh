#!/bin/bash

# CommandAI 高级调试脚本
# 用于深度诊断终端卡死问题

echo "🔍 CommandAI 高级调试分析"
echo "========================="

# 设置调试模式
set -x

echo "1. 检查当前进程状态..."
echo "Python 进程:"
ps aux | grep python3 | grep -v grep || echo "无 Python 进程"
echo "Zsh 进程:"
ps aux | grep zsh | grep -v grep || echo "无 Zsh 进程"

echo -e "\n2. 测试 Python 脚本各个功能..."
HELPER_SCRIPT="$HOME/.oh-my-zsh/custom/plugins/command-ai/bin/command-ai-helper"

echo "测试 cache 功能:"
timeout 3s python3 "$HELPER_SCRIPT" cache --cache-action stats 2>&1 || echo "cache 功能超时或失败"

echo "测试 translate 功能（简单测试）:"
timeout 5s python3 "$HELPER_SCRIPT" translate --query "list files" 2>&1 || echo "translate 功能超时或失败"

echo "测试 correct 功能:"
timeout 3s python3 "$HELPER_SCRIPT" correct --query "ls" --error "command not found" 2>&1 || echo "correct 功能超时或失败"

echo -e "\n3. 检查配置文件详细内容..."
CONFIG_FILE="$HOME/.config/command-ai/config.ini"
echo "配置文件前20行:"
head -20 "$CONFIG_FILE"

echo -e "\n4. 检查模块加载..."
PLUGIN_DIR="$HOME/.oh-my-zsh/custom/plugins/command-ai"
echo "检查主插件文件语法:"
zsh -n "$PLUGIN_DIR/command-ai.plugin.zsh" 2>&1 || echo "主插件语法错误"

echo "检查各模块语法:"
for module in "$PLUGIN_DIR/modules"/*.zsh; do
    echo "检查 $(basename "$module"):"
    zsh -n "$module" 2>&1 || echo "$(basename "$module") 语法错误"
done

echo -e "\n5. 模拟插件加载过程..."
echo "设置环境变量:"
export COMMAND_AI_PLUGIN_DIR="$PLUGIN_DIR"
export COMMAND_AI_CONFIG="$CONFIG_FILE"
export COMMAND_AI_CACHE_DIR="$HOME/.cache/command-ai"

echo "测试目录创建:"
[[ ! -d "$(dirname "$COMMAND_AI_CONFIG")" ]] && mkdir -p "$(dirname "$COMMAND_AI_CONFIG")"
[[ ! -d "$COMMAND_AI_CACHE_DIR" ]] && mkdir -p "$COMMAND_AI_CACHE_DIR"

echo "测试模块加载:"
for module in "$PLUGIN_DIR/modules"/*.zsh; do
    echo "加载 $(basename "$module")..."
    timeout 2s zsh -c "source '$module'; echo '$(basename "$module") 加载成功'" 2>&1 || echo "$(basename "$module") 加载超时或失败"
done

echo -e "\n6. 检查钩子函数..."
echo "测试 precmd 钩子:"
timeout 3s zsh -c "
source '$PLUGIN_DIR/modules/correction.zsh'
command_ai_precmd_hook
echo 'precmd 钩子测试完成'
" 2>&1 || echo "precmd 钩子超时或失败"

echo -e "\n7. 检查网络和 API 调用..."
echo "测试 API 连接:"
timeout 5s curl -s -H "Authorization: Bearer $(grep '^key' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')" \
    "https://api.moonshot.cn/v1/models" | head -100 2>&1 || echo "API 连接失败"

echo -e "\n8. 检查文件权限和依赖..."
echo "检查关键文件权限:"
ls -la "$PLUGIN_DIR/command-ai.plugin.zsh"
ls -la "$HELPER_SCRIPT"
ls -la "$CONFIG_FILE"

echo "检查 Python 模块导入:"
python3 -c "
import sys
sys.path.insert(0, '$(dirname "$HELPER_SCRIPT")')
try:
    import configparser
    import requests
    import sqlite3
    import json
    import hashlib
    import argparse
    print('所有必需模块导入成功')
except ImportError as e:
    print('模块导入失败:', e)
" 2>&1

echo -e "\n9. 生成最小测试配置..."
TEST_CONFIG="/tmp/commandai-test-config.ini"
cat > "$TEST_CONFIG" << 'EOF'
[api]
key = test-key
url = https://httpbin.org/post
model = test-model

[features]
auto_correction = false
smart_completion = false
natural_language = false
command_cache = false
security_check = false
EOF

echo "测试最小配置:"
timeout 3s python3 "$HELPER_SCRIPT" cache --cache-action stats 2>&1 || echo "最小配置测试失败"

echo -e "\n10. 系统资源检查..."
echo "内存使用:"
free -h
echo "磁盘空间:"
df -h "$HOME" | tail -1
echo "临时目录:"
ls -la /tmp/command* 2>/dev/null || echo "无相关临时文件"

echo -e "\n🔧 调试结果分析:"
echo "================================="
echo "如果看到以下问题，请按对应方法修复:"
echo "1. Python 脚本超时 -> 网络问题或 API 配置错误"
echo "2. 模块语法错误 -> 重新安装插件"
echo "3. precmd 钩子失败 -> 禁用自动纠错功能"
echo "4. API 连接失败 -> 检查 API Key 和网络"
echo "5. 权限问题 -> 重新设置文件权限"

echo -e "\n💡 紧急修复方案:"
echo "如果终端仍然卡死，执行以下命令:"
echo "1. 临时禁用插件: sed -i 's/plugins=(git command-ai)/plugins=(git)/' ~/.zshrc"
echo "2. 重新加载: source ~/.zshrc"
echo "3. 然后重新配置插件"
