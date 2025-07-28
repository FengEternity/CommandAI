#!/bin/bash

# CommandAI 紧急修复脚本
# 当终端卡死时使用此脚本快速恢复

echo "🚨 CommandAI 紧急修复脚本"
echo "========================"

echo "1. 备份当前配置..."
cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
echo "✅ 已备份 .zshrc"

echo "2. 临时禁用 CommandAI 插件..."
sed -i 's/plugins=(.*command-ai.*)/plugins=(git)/' ~/.zshrc
echo "✅ 已禁用 CommandAI 插件"

echo "3. 创建最小化配置..."
SAFE_CONFIG="$HOME/.config/command-ai/config-safe.ini"
cat > "$SAFE_CONFIG" << 'EOF'
[api]
key = your_api_key_here
url = https://api.moonshot.cn/v1
model = moonshot-v1-auto

[features]
auto_correction = false
smart_completion = false
natural_language = false
command_cache = false
security_check = false

[correction]
auto_trigger = false
show_suggestions = false
max_suggestions = 1

[completion]
enabled = false
timeout = 1
max_suggestions = 1
async_mode = false

[natural_language]
enabled = false
prefix = "#"
auto_execute = false
show_explanation = false

[advanced]
request_timeout = 3
max_retries = 1
debug_mode = true
EOF

echo "✅ 已创建安全配置: $SAFE_CONFIG"

echo "4. 创建测试脚本..."
cat > "$HOME/test-commandai.sh" << 'EOF'
#!/bin/bash
# CommandAI 安全测试脚本

echo "测试 CommandAI 基本功能..."

# 设置安全配置
export COMMAND_AI_CONFIG="$HOME/.config/command-ai/config-safe.ini"

# 测试 Python 脚本
HELPER="$HOME/.oh-my-zsh/custom/plugins/command-ai/bin/command-ai-helper"

if [[ -x "$HELPER" ]]; then
    echo "测试缓存功能:"
    timeout 3s python3 "$HELPER" cache --cache-action stats 2>/dev/null && echo "✅ 缓存功能正常" || echo "❌ 缓存功能异常"
    
    echo "测试翻译功能:"
    timeout 5s python3 "$HELPER" translate --query "list files" 2>/dev/null && echo "✅ 翻译功能正常" || echo "❌ 翻译功能异常"
else
    echo "❌ 辅助脚本不存在或无执行权限"
fi

echo "如果所有测试都正常，可以重新启用插件"
EOF

chmod +x "$HOME/test-commandai.sh"
echo "✅ 已创建测试脚本: ~/test-commandai.sh"

echo "5. 清理可能的问题文件..."
rm -f /tmp/command_ai_* 2>/dev/null
echo "✅ 已清理临时文件"

echo -e "\n🎯 修复完成！现在请执行以下步骤:"
echo "1. 重新加载 shell: source ~/.zshrc"
echo "2. 确认终端正常工作"
echo "3. 运行测试: ~/test-commandai.sh"
echo "4. 如果测试通过，可以重新启用插件"

echo -e "\n🔄 重新启用插件的步骤:"
echo "1. 编辑 ~/.zshrc，将 plugins=(git) 改为 plugins=(git command-ai)"
echo "2. 使用安全配置: cp ~/.config/command-ai/config-safe.ini ~/.config/command-ai/config.ini"
echo "3. 重新加载: source ~/.zshrc"

echo -e "\n⚠️  如果问题仍然存在:"
echo "1. 检查是否有其他 zsh 插件冲突"
echo "2. 尝试在新的终端窗口中测试"
echo "3. 考虑使用 bash 而不是 zsh 作为临时方案"

echo -e "\n📞 获取更多帮助:"
echo "运行 ./debug-advanced.sh 获取详细诊断信息"
