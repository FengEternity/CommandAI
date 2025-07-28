#!/bin/bash

# CommandAI 快速测试脚本
# 验证项目的基本完整性

echo "🧪 CommandAI 快速测试"
echo "==================="

# 获取项目根目录（脚本在 scripts/ 子目录中）
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
echo "📁 项目目录: $PROJECT_DIR"
echo

# 测试计数器
PASS=0
FAIL=0

test_pass() {
    echo "✅ $1"
    ((PASS++))
}

test_fail() {
    echo "❌ $1"
    ((FAIL++))
}

# 1. 检查必要文件
echo
echo "📁 检查文件结构..."
required_files=(
    "command-ai.plugin.zsh"
    "bin/command-ai-helper"
    "modules/correction.zsh"
    "modules/completion.zsh"
    "modules/nl2cmd.zsh"
    "modules/security.zsh"
    "modules/cache.zsh"
    "completions/_command-ai"
    "config.example.ini"
    "install.sh"
    "README.md"
)

for file in "${required_files[@]}"; do
    # 对于 install.sh，在 scripts 目录中查找
    if [[ "$file" == "install.sh" ]]; then
        file_path="$PROJECT_DIR/scripts/$file"
    # 对于 config.example.ini，在 config 目录中查找
    elif [[ "$file" == "config.example.ini" ]]; then
        file_path="$PROJECT_DIR/config/$file"
    # 其他文件在项目根目录中查找
    else
        file_path="$PROJECT_DIR/$file"
    fi
    
    if [[ -f "$file_path" ]]; then
        test_pass "文件存在: $file"
    else
        test_fail "文件缺失: $file"
    fi
done

# 2. 检查脚本权限
echo
echo "🔐 检查脚本权限..."
executable_files=(
    "bin/command-ai-helper"
    "install.sh"
)

for file in "${executable_files[@]}"; do
    # 对于 install.sh和demo.sh，在 scripts 目录中查找
    if [[ "$file" == "install.sh" || "$file" == "demo.sh" ]]; then
        file_path="$PROJECT_DIR/scripts/$file"
    # 其他文件在项目根目录中查找
    else
        file_path="$PROJECT_DIR/$file"
    fi
    
    if [[ -x "$file_path" ]]; then
        test_pass "可执行: $file"
    else
        test_fail "不可执行: $file"
    fi
done

# 3. 检查 Python 脚本
echo
echo "🐍 检查 Python 脚本..."
if command -v python3 &> /dev/null; then
    if python3 -m py_compile "$PROJECT_DIR/bin/command-ai-helper" 2>/dev/null; then
        test_pass "Python 脚本语法正确"
    else
        test_fail "Python 脚本语法错误"
    fi
    
    if python3 "$PROJECT_DIR/bin/command-ai-helper" --help &>/dev/null; then
        test_pass "Python 脚本可以运行"
    else
        test_fail "Python 脚本无法运行"
    fi
else
    test_fail "Python3 未安装"
fi

# 4. 检查 Zsh 脚本语法
echo
echo "🐚 检查 Zsh 脚本语法..."
if command -v zsh &> /dev/null; then
    zsh_files=(
        "command-ai.plugin.zsh"
        "modules/correction.zsh"
        "modules/completion.zsh"
        "modules/nl2cmd.zsh"
        "modules/security.zsh"
        "modules/cache.zsh"
        "completions/_command-ai"
    )
    
    for file in "${zsh_files[@]}"; do
        file_path="$PROJECT_DIR/$file"
        if zsh -n "$file_path" 2>/dev/null; then
            test_pass "Zsh 语法正确: $file"
        else
            test_fail "Zsh 语法错误: $file"
        fi
    done
else
    test_fail "Zsh 未安装"
fi

# 5. 检查配置文件
echo
echo "⚙️  检查配置文件..."
if command -v python3 &> /dev/null; then
    if python3 -c "
import configparser
config = configparser.ConfigParser()
config.read('$PROJECT_DIR/config/config.example.ini')
print('配置文件格式正确')
" &>/dev/null; then
        test_pass "配置文件格式正确"
    else
        test_fail "配置文件格式错误"
    fi
else
    test_fail "无法测试配置文件（Python3 未安装）"
fi

# 6. 检查缓存功能
echo
echo "💾 检查缓存功能..."
if python3 "$PROJECT_DIR/bin/command-ai-helper" cache --cache-action stats &>/dev/null; then
    test_pass "缓存功能可用"
else
    test_fail "缓存功能不可用"
fi

# 7. 检查安装脚本
echo
echo "📦 检查安装脚本..."
if bash -n "$PROJECT_DIR/scripts/install.sh" 2>/dev/null; then
    test_pass "安装脚本语法正确"
else
    test_fail "安装脚本语法错误"
fi

# 总结
echo
echo "📊 测试结果"
echo "============"
echo "✅ 通过: $PASS"
echo "❌ 失败: $FAIL"
echo "📈 总计: $((PASS + FAIL))"

if [[ $FAIL -eq 0 ]]; then
    echo
    echo "🎉 所有测试通过！CommandAI 已准备好使用。"
    echo
    echo "🚀 下一步："
    echo "1. 运行 ./install.sh 安装插件"
    echo "2. 配置 API Key 在 ~/.config/command-ai/config.ini"
    echo "3. 重启终端或运行 source ~/.zshrc"
    echo "4. 运行 ai help 查看使用说明"
    exit 0
else
    echo
    echo "⚠️  有 $FAIL 个测试失败，请检查并修复。"
    exit 1
fi
