#!/bin/bash

# CommandAI 演示脚本
# 展示 CommandAI 的主要功能

set -e

# 颜色定义
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_demo() {
    echo -e "${CYAN}$1${NC}"
}

print_command() {
    echo -e "${GREEN}$ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

echo "🚀 CommandAI 功能演示"
echo "===================="
echo

print_info "CommandAI 是一个智能的 Zsh 终端助手，集成了 AI 功能"
echo

print_demo "1. 自然语言转命令"
print_info "使用自然语言描述，AI 会生成对应的命令"
print_command "ai 列出当前目录下的所有 .txt 文件"
print_command "ai 查找包含 'error' 的日志文件"
print_command "ai 统计当前目录下的文件数量"
echo

print_demo "2. 智能命令纠错"
print_info "当命令执行失败时，AI 会自动分析并提供修复建议"
print_command "lst  # 错误命令，会自动触发纠错"
print_command "ai fix  # 手动修复上一个命令"
echo

print_demo "3. 智能补全"
print_info "按 Tab 键或 Ctrl+Space 获取 AI 增强的补全建议"
print_command "docker run <Tab>  # 获取智能补全"
print_command "git commit <Tab>  # 获取上下文相关的补全"
echo

print_demo "4. 安全功能"
print_info "自动检测危险命令并要求确认"
print_command "ai 删除所有 .tmp 文件  # 会显示安全警告"
echo

print_demo "5. 缓存管理"
print_info "智能缓存常用命令，提高响应速度"
print_command "ai cache stats  # 查看缓存统计"
print_command "ai cache clear  # 清空缓存"
echo

print_demo "6. 配置管理"
print_info "灵活的配置选项"
print_command "ai config  # 打开配置文件"
print_command "ai security status  # 查看安全设置"
echo

print_demo "7. 反馈系统"
print_info "对 AI 建议进行反馈，持续改进"
print_command "ai feedback good  # 标记为好的建议"
print_command "ai feedback bad   # 标记为坏的建议"
echo

print_info "开始使用："
print_command "./install.sh  # 安装 CommandAI"
print_command "source ~/.zshrc  # 重新加载配置"
print_command "ai help  # 查看完整帮助"
echo

echo "🎯 主要特性："
echo "  ✅ 智能命令纠错"
echo "  ✅ AI 增强补全"
echo "  ✅ 自然语言转命令"
echo "  ✅ 安全检查和确认"
echo "  ✅ 智能缓存系统"
echo "  ✅ 用户反馈学习"
echo "  ✅ 模块化架构"
echo "  ✅ 丰富的配置选项"
echo

echo "📚 更多信息请查看 README.md"
