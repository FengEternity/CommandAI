#!/usr/bin/env zsh

# CommandAI 智能补全模块
# 提供基于 AI 的智能命令补全功能

# 全局变量
typeset -g COMMAND_AI_COMPLETION_ENABLED=1
typeset -g COMMAND_AI_COMPLETION_CACHE=()
typeset -g COMMAND_AI_COMPLETION_TIMEOUT=5

# 智能补全主函数
command_ai_smart_completion() {
    # 如果补全功能被禁用，使用默认补全
    if [[ $COMMAND_AI_COMPLETION_ENABLED -eq 0 ]]; then
        zle expand-or-complete
        return
    fi
    
    # 获取当前输入
    local current_input="$BUFFER"
    local cursor_pos=$CURSOR
    
    # 如果输入为空，使用默认补全
    if [[ -z "$current_input" ]]; then
        zle expand-or-complete
        return
    fi
    
    # 检查是否应该使用 AI 补全
    if command_ai_should_use_ai_completion "$current_input"; then
        command_ai_ai_completion "$current_input" "$cursor_pos"
    else
        # 使用默认补全
        zle expand-or-complete
    fi
}

# 判断是否应该使用 AI 补全
command_ai_should_use_ai_completion() {
    local input="$1"
    
    # 如果输入包含复杂的命令结构，使用 AI 补全
    if [[ "$input" =~ (find|grep|awk|sed|curl|wget|docker|kubectl|git).* ]]; then
        return 0
    fi
    
    # 如果输入包含管道或重定向，使用 AI 补全
    if [[ "$input" =~ .*[\|\>\<].* ]]; then
        return 0
    fi
    
    # 如果输入较长，使用 AI 补全
    if [[ ${#input} -gt 20 ]]; then
        return 0
    fi
    
    # 默认使用传统补全
    return 1
}

# AI 补全实现
command_ai_ai_completion() {
    local current_input="$1"
    local cursor_pos="$2"
    
    # 显示加载提示
    print -P "\n%F{cyan}CommandAI: 正在获取智能补全建议...%f"
    
    # 异步获取 AI 补全建议
    command_ai_get_ai_completions "$current_input" &
    local completion_pid=$!
    
    # 等待补全结果，但有超时限制
    local timeout=$COMMAND_AI_COMPLETION_TIMEOUT
    local count=0
    
    while [[ $count -lt $timeout ]]; do
        if ! kill -0 $completion_pid 2>/dev/null; then
            break
        fi
        sleep 0.2
        ((count++))
    done
    
    # 如果超时，终止进程
    if kill -0 $completion_pid 2>/dev/null; then
        kill $completion_pid 2>/dev/null
        print -P "%F{yellow}CommandAI: 补全请求超时，使用默认补全%f"
        zle expand-or-complete
        return
    fi
    
    # 读取补全结果
    if [[ -f "/tmp/command_ai_completions_$$" ]]; then
        local completions_json=$(cat "/tmp/command_ai_completions_$$")
        rm -f "/tmp/command_ai_completions_$$"
        
        if [[ -n "$completions_json" ]]; then
            command_ai_present_completions "$completions_json" "$current_input"
        else
            print -P "%F{yellow}CommandAI: 未获取到补全建议，使用默认补全%f"
            zle expand-or-complete
        fi
    else
        print -P "%F{yellow}CommandAI: 补全服务不可用，使用默认补全%f"
        zle expand-or-complete
    fi
}

# 异步获取 AI 补全建议
command_ai_get_ai_completions() {
    local current_input="$1"
    local context=$(command_ai_get_context)
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    
    if [[ -x "$helper_script" ]]; then
        # 使用 timeout 命令防止卡死，最多等待 5 秒
        local completions=$(timeout 5s python3 "$helper_script" complete \
            --query "$current_input" \
            --context "$context" 2>/dev/null)
        
        # 检查是否超时
        if [[ $? -eq 124 ]]; then
            echo "timeout" > "/tmp/command_ai_completions_$$"
        else
            echo "$completions" > "/tmp/command_ai_completions_$$"
        fi
    fi
}

# 展示补全建议
command_ai_present_completions() {
    local completions_json="$1"
    local current_input="$2"
    
    # 解析 JSON 补全建议
    local completions=()
    local descriptions=()
    
    # 使用 Python 解析 JSON（简单实现）
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    if [[ -x "$helper_script" ]]; then
        # 创建临时脚本解析 JSON
        cat > "/tmp/parse_completions_$$.py" << 'EOF'
import json
import sys

try:
    data = json.loads(sys.argv[1])
    for item in data:
        print(f"{item.get('completion', '')}|{item.get('description', '')}")
except:
    pass
EOF
        
        local parsed_output=$(python3 "/tmp/parse_completions_$$.py" "$completions_json" 2>/dev/null)
        rm -f "/tmp/parse_completions_$$.py"
        
        if [[ -n "$parsed_output" ]]; then
            # 构建补全菜单
            local -a completion_items
            local -a completion_descriptions
            
            while IFS='|' read -r completion description; do
                if [[ -n "$completion" ]]; then
                    completion_items+=("$completion")
                    completion_descriptions+=("$description")
                fi
            done <<< "$parsed_output"
            
            if [[ ${#completion_items[@]} -gt 0 ]]; then
                command_ai_show_completion_menu "$completion_items" "$completion_descriptions" "$current_input"
                return
            fi
        fi
    fi
    
    # 如果解析失败，使用默认补全
    print -P "%F{yellow}CommandAI: 补全解析失败，使用默认补全%f"
    zle expand-or-complete
}

# 显示补全菜单
command_ai_show_completion_menu() {
    local -a completions=("${(@)1}")
    local -a descriptions=("${(@)2}")
    local current_input="$3"
    
    print -P "\n%F{cyan}CommandAI 智能补全建议:%f"
    
    local i=1
    for completion in "${completions[@]}"; do
        local desc="${descriptions[$i]:-}"
        if [[ -n "$desc" ]]; then
            print -P "  %F{green}$i%f) %F{white}$completion%f - %F{yellow}$desc%f"
        else
            print -P "  %F{green}$i%f) %F{white}$completion%f"
        fi
        ((i++))
    done
    
    echo
    print -P "%F{cyan}请选择补全项 (1-${#completions[@]}) 或按 Enter 使用默认补全:%f"
    
    read -k1 "choice"
    echo
    
    if [[ "$choice" =~ ^[1-9]$ && "$choice" -le "${#completions[@]}" ]]; then
        local selected_completion="${completions[$choice]}"
        
        # 智能替换当前输入
        local new_buffer=$(command_ai_smart_replace "$current_input" "$selected_completion")
        BUFFER="$new_buffer"
        CURSOR=${#BUFFER}
        
        print -P "%F{green}✓ 已应用补全: $selected_completion%f"
        
        # 记录使用情况
        command_ai_record_completion_usage "$current_input" "$selected_completion"
    else
        # 使用默认补全
        zle expand-or-complete
    fi
}

# 智能替换输入
command_ai_smart_replace() {
    local current_input="$1"
    local completion="$2"
    
    # 如果补全是完整命令，直接替换
    if [[ "$completion" =~ ^[a-zA-Z0-9_-]+.* ]]; then
        echo "$completion"
        return
    fi
    
    # 如果补全是参数或选项，智能追加
    if [[ "$completion" =~ ^--.* || "$completion" =~ ^-.* ]]; then
        echo "$current_input $completion"
        return
    fi
    
    # 默认追加
    echo "$current_input $completion"
}

# 记录补全使用情况
command_ai_record_completion_usage() {
    local query="$1"
    local completion="$2"
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    
    if [[ -x "$helper_script" ]]; then
        python3 "$helper_script" feedback \
            --query "completion:$query" \
            --command "$completion" \
            --feedback-type "good" \
            --context "$(command_ai_get_context)" >/dev/null 2>&1 &
    fi
}

# 注册 ZLE 函数
zle -N command_ai_smart_completion

# 补全配置管理
command_ai_completion_config() {
    case "$1" in
        enable)
            COMMAND_AI_COMPLETION_ENABLED=1
            print -P "%F{green}CommandAI: 智能补全已启用%f"
            ;;
        disable)
            COMMAND_AI_COMPLETION_ENABLED=0
            print -P "%F{yellow}CommandAI: 智能补全已禁用%f"
            ;;
        timeout)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                COMMAND_AI_COMPLETION_TIMEOUT="$2"
                print -P "%F{cyan}CommandAI: 补全超时设置为 ${2}s%f"
            else
                print -P "%F{red}CommandAI: 无效的超时值%f"
            fi
            ;;
        status)
            local status="禁用"
            [[ $COMMAND_AI_COMPLETION_ENABLED -eq 1 ]] && status="启用"
            print -P "%F{cyan}智能补全状态: $status%f"
            print -P "%F{cyan}补全超时: ${COMMAND_AI_COMPLETION_TIMEOUT}s%f"
            ;;
        *)
            print -P "%F{cyan}用法: ai completion <enable|disable|timeout|status> [value]%f"
            ;;
    esac
}

# 手动触发补全
command_ai_manual_completion() {
    if [[ -n "$BUFFER" ]]; then
        command_ai_ai_completion "$BUFFER" "$CURSOR"
    else
        print -P "%F{yellow}CommandAI: 请先输入命令%f"
    fi
}

# 注册手动补全函数
zle -N command_ai_manual_completion

# 绑定额外的快捷键
bindkey '^X^A' command_ai_manual_completion  # Ctrl+X Ctrl+A
