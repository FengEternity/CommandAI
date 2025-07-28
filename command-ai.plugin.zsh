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

# 如果配置文件不存在，复制示例配置
if [[ ! -f "$COMMAND_AI_CONFIG" ]]; then
    if [[ -f "$COMMAND_AI_PLUGIN_DIR/config.example.ini" ]]; then
        cp "$COMMAND_AI_PLUGIN_DIR/config.example.ini" "$COMMAND_AI_CONFIG"
        echo "CommandAI: 配置文件已创建在 $COMMAND_AI_CONFIG"
        echo "请编辑配置文件设置您的 API Key"
    fi
fi

# 加载所有模块
for module in "$COMMAND_AI_PLUGIN_DIR/modules"/*.zsh; do
    [[ -r "$module" ]] && source "$module"
done

# 设置补全路径
fpath=("$COMMAND_AI_PLUGIN_DIR/completions" $fpath)

# 初始化补全系统
autoload -Uz compinit
compinit

# 绑定快捷键
bindkey '^I' command_ai_smart_completion  # Tab 键
bindkey '^@' command_ai_smart_completion  # Ctrl+Space

# 设置钩子
autoload -Uz add-zsh-hook
add-zsh-hook precmd command_ai_precmd_hook

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

# 绑定自然语言前缀处理
zle -N command_ai_nl_prefix
bindkey '^M' command_ai_nl_prefix  # Enter 键

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
echo "CommandAI 已加载！输入 'ai help' 查看使用说明。"
