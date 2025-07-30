#!/usr/bin/env zsh

# CommandAI: 您的智能 Zsh 终端助手
# 版本: 1.0.0
# 作者: CommandAI Team

# 获取插件目录
COMMAND_AI_PLUGIN_DIR="${0:A:h}"

# 配置文件路径
COMMAND_AI_CONFIG="${COMMAND_AI_CONFIG:-$HOME/.config/command-ai/config.ini}"

# 缓存目录
COMMAND_AI_CACHE_DIR="${COMMAND_AI_CACHE_DIR:-$HOME/.cache/command-ai}"

# 创建必要的目录
[[ ! -d "$(dirname "$COMMAND_AI_CONFIG")" ]] && mkdir -p "$(dirname "$COMMAND_AI_CONFIG")"
[[ ! -d "$COMMAND_AI_CACHE_DIR" ]] && mkdir -p "$COMMAND_AI_CACHE_DIR"

# 如果配置文件不存在，提示用户创建
if [[ ! -f "$COMMAND_AI_CONFIG" ]]; then
    echo "CommandAI: 配置文件不存在，请运行安装脚本或手动创建 $COMMAND_AI_CONFIG"
fi

# 加载所有模块
if [[ -d "$COMMAND_AI_PLUGIN_DIR/modules" ]]; then
    for module in "$COMMAND_AI_PLUGIN_DIR/modules"/*.zsh; do
        if [[ -r "$module" ]]; then
            if ! source "$module" 2>/dev/null; then
                echo "CommandAI: 警告 - 模块加载失败: $(basename "$module")"
            fi
        fi
    done
else
    echo "CommandAI: 警告 - 模块目录不存在: $COMMAND_AI_PLUGIN_DIR/modules"
fi

# 设置补全路径
fpath=("$COMMAND_AI_PLUGIN_DIR/completions" $fpath)

# 初始化补全系统
autoload -Uz compinit
compinit

# 绑定快捷键（默认禁用以避免冲突）
# bindkey '^I' command_ai_smart_completion  # Tab 键
# bindkey '^@' command_ai_smart_completion  # Ctrl+Space

# 设置钩子
if (( $+functions[command_ai_precmd_hook] )); then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd command_ai_precmd_hook
else
    echo "CommandAI: 警告 - precmd 钩子函数不存在"
fi

# 定义主要命令
ai() {
    case "$1" in
        fix)
            command_ai_fix_command "${@:2}"
            ;;
        feedback)
            command_ai_feedback "${@:2}"
            ;;
        config)
            command_ai_config "${@:2}"
            ;;
        cache)
            command_ai_cache_management "${@:2}"
            ;;
        help|--help|-h)
            command_ai_show_help
            ;;
        *)
            # 自然语言转命令
            command_ai_nl2cmd "$@"
            ;;
    esac
}

# 自然语言转命令的快捷方式
command_ai_nl_prefix() {
    if [[ "$BUFFER" =~ '^#(.*)' ]]; then
        local nl_query="${match[1]# }"
        if [[ -n "$nl_query" ]]; then
            local cmd=$(command_ai_translate_nl "$nl_query")
            if [[ -n "$cmd" ]]; then
                BUFFER="$cmd"
                CURSOR=${#BUFFER}
            fi
        fi
    fi
}

# 绑定自然语言前缀处理（默认禁用以避免冲突）
# zle -N command_ai_nl_prefix
# bindkey '^M' command_ai_nl_prefix  # Enter 键

# 显示帮助信息
command_ai_show_help() {
    cat << 'EOF'
CommandAI - 您的智能 Zsh 终端助手

用法:
  ai <自然语言描述>     - 将自然语言转换为命令
  ai fix [命令]         - 修复上一个或指定的命令
  ai feedback <good|bad> - 对 AI 建议提供反馈
  ai config            - 打开配置文件
  ai cache <clear|stats> - 管理缓存
  ai help              - 显示此帮助信息

快捷键:
  Tab / Ctrl+Space     - 智能补全
  # <描述> + Enter      - 自然语言转命令

示例:
  ai 列出当前目录下的所有 .txt 文件
  ai fix
  ai feedback good
  # 查找包含 "error" 的日志文件

配置文件: $COMMAND_AI_CONFIG
缓存目录: $COMMAND_AI_CACHE_DIR
EOF
}

# 初始化消息
# echo "CommandAI 已加载！输入 'ai help' 查看使用说明。"
