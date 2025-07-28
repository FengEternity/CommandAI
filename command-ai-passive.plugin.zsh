#!/usr/bin/env zsh

# CommandAI: 被动模式智能 Zsh 终端助手
# 版本: 1.1.0 (被动模式)
# 作者: CommandAI Team
# 
# 被动模式特点：
# - 不拦截任何用户命令
# - 不重新绑定 Tab 键
# - 不使用 precmd 钩子
# - 只在用户主动调用时工作

# 获取插件目录
COMMAND_AI_PLUGIN_DIR="${0:A:h}"

# 配置文件路径
COMMAND_AI_CONFIG="${COMMAND_AI_CONFIG:-$HOME/.config/command-ai/config.ini}"

# 缓存目录
COMMAND_AI_CACHE_DIR="${COMMAND_AI_CACHE_DIR:-$HOME/.cache/command-ai}"

# 调试模式
COMMAND_AI_DEBUG="${COMMAND_AI_DEBUG:-0}"

# 调试日志函数
command_ai_debug_log() {
    if [[ "$COMMAND_AI_DEBUG" == "1" ]]; then
        echo "[CommandAI DEBUG $(date '+%H:%M:%S')] $*" >&2
    fi
}

command_ai_debug_log "开始加载 CommandAI 插件（被动模式）"

# 创建必要的目录
[[ ! -d "$(dirname "$COMMAND_AI_CONFIG")" ]] && mkdir -p "$(dirname "$COMMAND_AI_CONFIG")"
[[ ! -d "$COMMAND_AI_CACHE_DIR" ]] && mkdir -p "$COMMAND_AI_CACHE_DIR"

# 如果配置文件不存在，复制示例配置
if [[ ! -f "$COMMAND_AI_CONFIG" ]]; then
    if [[ -f "$COMMAND_AI_PLUGIN_DIR/config.example.ini" ]]; then
        cp "$COMMAND_AI_PLUGIN_DIR/config.example.ini" "$COMMAND_AI_CONFIG"
        command_ai_debug_log "配置文件已创建在 $COMMAND_AI_CONFIG"
        echo "CommandAI: 配置文件已创建在 $COMMAND_AI_CONFIG"
        echo "请编辑配置文件设置您的 API Key"
    fi
fi

# 定义必要的辅助函数
command_ai_get_context() {
    local context=""
    context+="cwd:$(pwd);"
    context+="user:$(whoami);"
    context+="shell:$SHELL;"
    echo "$context"
}

# 缓存管理函数
command_ai_cache_management() {
    local action="$1"
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    
    if [[ -x "$helper_script" ]]; then
        case "$action" in
            stats)
                timeout 5s python3 "$helper_script" cache --cache-action stats 2>/dev/null || echo "缓存统计获取失败"
                ;;
            clear)
                timeout 5s python3 "$helper_script" cache --cache-action clear 2>/dev/null || echo "缓存清理失败"
                echo "缓存已清理"
                ;;
            *)
                echo "用法: ai cache <stats|clear>"
                ;;
        esac
    else
        echo "CommandAI: 辅助脚本不可用"
    fi
}

# 配置管理函数
command_ai_config() {
    echo "配置文件位置: $COMMAND_AI_CONFIG"
    echo "缓存目录: $COMMAND_AI_CACHE_DIR"
    echo "调试模式: $COMMAND_AI_DEBUG"
    
    if [[ -f "$COMMAND_AI_CONFIG" ]]; then
        echo "配置文件存在，大小: $(wc -c < "$COMMAND_AI_CONFIG") 字节"
    else
        echo "配置文件不存在"
    fi
}

# 反馈函数
command_ai_feedback() {
    echo "反馈功能: $*"
    echo "此功能在被动模式下简化实现"
}

# 简化的自然语言转命令函数
command_ai_nl2cmd() {
    local nl_query="$*"
    
    if [[ -z "$nl_query" ]]; then
        echo "CommandAI: 请提供自然语言描述"
        echo "示例: ai 列出当前目录下的所有 .txt 文件"
        return 1
    fi
    
    command_ai_debug_log "处理自然语言查询: $nl_query"
    echo "CommandAI: 正在翻译自然语言: $nl_query"
    
    local context=$(command_ai_get_context)
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local generated_cmd
    
    if [[ -x "$helper_script" ]]; then
        command_ai_debug_log "调用辅助脚本进行翻译"
        generated_cmd=$(timeout 15s python3 "$helper_script" translate \
            --query "$nl_query" \
            --context "$context" 2>/dev/null)
        
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo "CommandAI: AI 请求超时，请检查网络连接"
            return 1
        elif [[ $exit_code -ne 0 ]]; then
            echo "CommandAI: 辅助脚本执行失败"
            return 1
        fi
    fi
    
    if [[ -n "$generated_cmd" ]]; then
        # 清理命令（移除可能的标签）
        local clean_cmd=$(echo "$generated_cmd" | sed 's/\[DANGER\]//g' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        
        echo "CommandAI: 生成的命令:"
        echo "  $clean_cmd"
        echo ""
        echo "选择操作:"
        echo "  1) 执行命令"
        echo "  2) 编辑命令"
        echo "  3) 取消"
        
        read -k1 "choice?请选择 (1/2/3): "
        echo ""
        
        case "$choice" in
            1)
                echo "执行: $clean_cmd"
                eval "$clean_cmd"
                ;;
            2)
                print -z "$clean_cmd"
                ;;
            *)
                echo "已取消"
                ;;
        esac
    else
        echo "CommandAI: 无法翻译自然语言，请检查配置或网络连接"
        return 1
    fi
}

command_ai_debug_log "核心函数已定义"

# 设置补全路径（但不重新绑定键）
fpath=("$COMMAND_AI_PLUGIN_DIR/completions" $fpath)

# 不重新绑定任何键！保持原有的 Tab 补全功能

# 不设置任何钩子！不拦截用户命令

# 定义主要命令（被动模式）
ai() {
    command_ai_debug_log "ai 命令被调用，参数: $*"
    
    case "$1" in
        fix)
            command_ai_debug_log "执行手动纠错"
            command_ai_manual_fix "${@:2}"
            ;;
        feedback)
            command_ai_debug_log "记录用户反馈"
            command_ai_feedback "${@:2}"
            ;;
        config)
            command_ai_debug_log "配置管理"
            command_ai_config "${@:2}"
            ;;
        cache)
            command_ai_debug_log "缓存管理"
            command_ai_cache_management "${@:2}"
            ;;
        debug)
            command_ai_debug_log "切换调试模式"
            if [[ "$COMMAND_AI_DEBUG" == "1" ]]; then
                export COMMAND_AI_DEBUG=0
                echo "CommandAI: 调试模式已关闭"
            else
                export COMMAND_AI_DEBUG=1
                echo "CommandAI: 调试模式已开启"
            fi
            ;;
        help|--help|-h)
            command_ai_debug_log "显示帮助信息"
            command_ai_show_help
            ;;
        *)
            command_ai_debug_log "自然语言转命令: $*"
            # 自然语言转命令
            command_ai_nl2cmd "$@"
            ;;
    esac
}

# 手动纠错功能（不使用钩子）
command_ai_manual_fix() {
    command_ai_debug_log "手动纠错功能被调用"
    
    local failed_cmd="$1"
    
    # 如果没有提供命令，尝试从历史记录获取
    if [[ -z "$failed_cmd" ]]; then
        failed_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
        command_ai_debug_log "从历史记录获取命令: $failed_cmd"
    fi
    
    if [[ -z "$failed_cmd" ]]; then
        echo "CommandAI: 请提供要修复的命令"
        echo "用法: ai fix <命令>"
        echo "或者: ai fix  # 修复上一个命令"
        return 1
    fi
    
    echo "CommandAI: 正在分析命令: $failed_cmd"
    
    # 调用辅助脚本获取纠错建议
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local corrected_cmd
    
    if [[ -x "$helper_script" ]]; then
        command_ai_debug_log "调用辅助脚本进行纠错"
        corrected_cmd=$(timeout 10s python3 "$helper_script" correct \
            --query "$failed_cmd" \
            --error "manual fix request" \
            --context "$(pwd)" 2>/dev/null)
        
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            echo "CommandAI: AI 请求超时，请检查网络连接"
            return 1
        elif [[ $exit_code -ne 0 ]]; then
            echo "CommandAI: 辅助脚本执行失败"
            return 1
        fi
    fi
    
    if [[ -n "$corrected_cmd" ]]; then
        echo "CommandAI: 建议的修复命令:"
        echo "  $corrected_cmd"
        echo ""
        echo "选择操作:"
        echo "  1) 执行修复后的命令"
        echo "  2) 编辑命令"
        echo "  3) 取消"
        
        read -k1 "choice?请选择 (1/2/3): "
        echo ""
        
        case "$choice" in
            1)
                echo "执行: $corrected_cmd"
                eval "$corrected_cmd"
                ;;
            2)
                print -z "$corrected_cmd"
                ;;
            *)
                echo "已取消"
                ;;
        esac
    else
        echo "CommandAI: 无法获取修复建议，请检查配置或网络连接"
    fi
}

# 显示帮助信息
command_ai_show_help() {
    cat << 'EOF'
CommandAI - 智能 Zsh 终端助手 (被动模式)

用法:
  ai <自然语言描述>     将自然语言转换为命令
  ai fix [命令]          手动修复命令
  ai cache <操作>        缓存管理 (clear/stats)
  ai config             配置管理
  ai debug              切换调试模式
  ai help               显示此帮助信息

示例:
  ai 列出当前目录的所有 txt 文件
  ai fix ls -la
  ai fix                # 修复上一个命令
  ai cache stats
  ai debug              # 开启/关闭调试日志

被动模式特点:
- 不会拦截或监控您的命令
- 不会重新绑定 Tab 键
- 只在您主动调用时工作
- 保持终端的原生体验

配置文件: ~/.config/command-ai/config.ini
缓存目录: ~/.cache/command-ai/
EOF
}

command_ai_debug_log "CommandAI 插件加载完成（被动模式）"

# 显示加载成功消息
if [[ "$COMMAND_AI_DEBUG" == "1" ]]; then
    echo "CommandAI 已加载（被动模式 + 调试）！输入 'ai help' 查看使用说明。"
else
    echo "CommandAI 已加载（被动模式）！输入 'ai help' 查看使用说明。"
fi
