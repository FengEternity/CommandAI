#!/usr/bin/env zsh

# CommandAI 命令纠错模块
# 提供智能命令纠错功能

# 全局变量
typeset -g COMMAND_AI_LAST_COMMAND=""
typeset -g COMMAND_AI_LAST_ERROR=""
typeset -g COMMAND_AI_CORRECTION_ENABLED=1

# precmd 钩子 - 检测命令执行失败
command_ai_precmd_hook() {
    local exit_code=$?
    
    # 如果纠错功能被禁用，直接返回
    [[ $COMMAND_AI_CORRECTION_ENABLED -eq 0 ]] && return
    
    # 如果自动纠错被禁用，也直接返回（避免频繁触发）
    [[ "${COMMAND_AI_AUTO_CORRECT:-1}" != "1" ]] && return
    
    # 获取最后执行的命令
    local last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    
    # 如果命令为空或是 ai 相关命令，跳过
    [[ -z "$last_cmd" || "$last_cmd" =~ ^ai.* ]] && return
    
    # 如果退出码表示命令未找到或权限错误
    if [[ $exit_code -eq 127 || $exit_code -eq 126 ]]; then
        COMMAND_AI_LAST_COMMAND="$last_cmd"
        
        # 获取错误信息（从历史记录或stderr）
        local error_info=""
        if [[ $exit_code -eq 127 ]]; then
            error_info="command not found"
        elif [[ $exit_code -eq 126 ]]; then
            error_info="permission denied"
        fi
        
        COMMAND_AI_LAST_ERROR="$error_info"
        
        # 自动触发纠错（如果启用）
        if [[ "${COMMAND_AI_AUTO_CORRECT:-1}" == "1" ]]; then
            echo
            print -P "%F{yellow}CommandAI: 检测到命令执行失败，正在分析...%f"
            command_ai_auto_correct "$last_cmd" "$error_info"
        else
            echo
            print -P "%F{cyan}CommandAI: 命令执行失败。输入 'ai fix' 获取修复建议。%f"
        fi
    fi
}

# 自动纠错函数
command_ai_auto_correct() {
    local failed_cmd="$1"
    local error_info="$2"
    local context=$(command_ai_get_context)
    
    # 调用辅助脚本获取纠错建议（添加超时机制）
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local corrected_cmd
    
    if [[ -x "$helper_script" ]]; then
        # 使用 timeout 命令防止卡死，最多等待 10 秒
        corrected_cmd=$(timeout 10s python3 "$helper_script" correct \
            --query "$failed_cmd" \
            --error "$error_info" \
            --context "$context" 2>/dev/null)
        
        # 检查 timeout 命令的退出状态
        local exit_code=$?
        if [[ $exit_code -eq 124 ]]; then
            print -P "%F{red}CommandAI: AI 请求超时，请检查网络连接。%f"
            return
        elif [[ $exit_code -ne 0 ]]; then
            print -P "%F{red}CommandAI: 辅助脚本执行失败。%f"
            return
        fi
    fi
    
    if [[ -n "$corrected_cmd" ]]; then
        command_ai_present_correction "$failed_cmd" "$corrected_cmd"
    else
        print -P "%F{red}CommandAI: 无法获取纠错建议，请检查配置或网络连接。%f"
    fi
}

# 手动纠错命令
command_ai_fix_command() {
    local first_arg="$1"
    
    # 检查是否使用 --analyze 或 -a 参数
    if [[ "$first_arg" == "--analyze" || "$first_arg" == "-a" ]]; then
        command_ai_analyze_history "${@:2}"
        return $?
    fi
    
    local target_cmd="$first_arg"
    
    # 如果没有指定命令，使用最后失败的命令
    if [[ -z "$target_cmd" ]]; then
        if [[ -n "$COMMAND_AI_LAST_COMMAND" ]]; then
            target_cmd="$COMMAND_AI_LAST_COMMAND"
        else
            # 获取历史记录中的最后一条命令
            target_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
        fi
    fi
    
    if [[ -z "$target_cmd" ]]; then
        print -P "%F{red}CommandAI: 没有找到需要修复的命令。%f"
        return 1
    fi
    
    print -P "%F{cyan}CommandAI: 正在分析命令: $target_cmd%f"
    
    local context=$(command_ai_get_context)
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local corrected_cmd
    
    if [[ -x "$helper_script" ]]; then
        corrected_cmd=$(python3 "$helper_script" correct \
            --query "$target_cmd" \
            --error "${COMMAND_AI_LAST_ERROR:-}" \
            --context "$context" 2>/dev/null)
    fi
    
    if [[ -n "$corrected_cmd" ]]; then
        command_ai_present_correction "$target_cmd" "$corrected_cmd"
    else
        print -P "%F{red}CommandAI: 无法获取纠错建议，请检查配置。%f"
        return 1
    fi
}

# 展示纠错建议并处理用户选择
command_ai_present_correction() {
    local original_cmd="$1"
    local corrected_cmd="$2"
    
    # 检查是否为危险命令
    if [[ "$corrected_cmd" =~ ^\[DANGER\] ]]; then
        corrected_cmd="${corrected_cmd#\[DANGER\] }"
        print -P "%F{red}⚠️  警告: 检测到潜在危险命令!%f"
        print -P "%F{red}原命令: $original_cmd%f"
        print -P "%F{red}建议命令: $corrected_cmd%f"
        print -P "%F{yellow}请仔细确认后再执行！%f"
        
        echo
        print -P "%F{cyan}请选择操作:%f"
        print -P "  %F{green}1%f) 执行建议命令"
        print -P "  %F{yellow}2%f) 编辑命令"
        print -P "  %F{red}3%f) 取消"
        
        read -k1 "choice?请输入选择 (1-3): "
        echo
        
        case $choice in
            1)
                print -P "%F{yellow}请再次确认执行危险命令 (输入 'yes' 确认): %f"
                read "confirm"
                if [[ "$confirm" == "yes" ]]; then
                    command_ai_execute_command "$corrected_cmd"
                else
                    print -P "%F{cyan}已取消执行。%f"
                fi
                ;;
            2)
                command_ai_edit_command "$corrected_cmd"
                ;;
            3)
                print -P "%F{cyan}已取消。%f"
                ;;
            *)
                print -P "%F{red}无效选择。%f"
                ;;
        esac
    else
        print -P "%F{green}原命令: $original_cmd%f"
        print -P "%F{cyan}建议命令: $corrected_cmd%f"
        
        echo
        print -P "%F{cyan}请选择操作:%f"
        print -P "  %F{green}1%f) 执行建议命令"
        print -P "  %F{yellow}2%f) 编辑命令"
        print -P "  %F{red}3%f) 取消"
        
        read -k1 "choice?请输入选择 (1-3): "
        echo
        
        case $choice in
            1)
                command_ai_execute_command "$corrected_cmd"
                ;;
            2)
                command_ai_edit_command "$corrected_cmd"
                ;;
            3)
                print -P "%F{cyan}已取消。%f"
                ;;
            *)
                print -P "%F{red}无效选择。%f"
                ;;
        esac
    fi
}

# 执行命令
command_ai_execute_command() {
    local cmd="$1"
    print -P "%F{green}执行命令: $cmd%f"
    
    # 将命令添加到历史记录
    print -s "$cmd"
    
    # 执行命令
    eval "$cmd"
    local exit_code=$?
    
    # 根据执行结果提供反馈
    if [[ $exit_code -eq 0 ]]; then
        print -P "%F{green}✓ 命令执行成功%f"
        command_ai_record_feedback "good" "$cmd"
    else
        print -P "%F{red}✗ 命令执行失败 (退出码: $exit_code)%f"
        command_ai_record_feedback "bad" "$cmd"
    fi
}

# 编辑命令
command_ai_edit_command() {
    local cmd="$1"
    
    # 将命令放入输入缓冲区供用户编辑
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
    
    print -P "%F{cyan}命令已放入输入缓冲区，请编辑后按 Enter 执行。%f"
}

# 分析历史命令及其执行结果
command_ai_analyze_history() {
    local count="${1:-5}"  # 默认分析最近5个命令
    
    print -P "%F{cyan}CommandAI: 正在分析最近 $count 个命令及其执行结果...%f"
    
    # 获取历史命令和执行状态
    local history_data=$(command_ai_get_command_history "$count")
    
    if [[ -z "$history_data" ]]; then
        print -P "%F{red}CommandAI: 无法获取历史命令数据。%f"
        return 1
    fi
    
    local context=$(command_ai_get_context)
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local analysis_result
    
    if [[ -x "$helper_script" ]]; then
        analysis_result=$(python3 "$helper_script" analyze \
            --history "$history_data" \
            --context "$context")
    fi
    
    if [[ -n "$analysis_result" ]]; then
        print -P "%F{green}分析结果:%f"
        echo "$analysis_result"
        
        # 询问是否需要执行建议的修复命令
        if [[ "$analysis_result" =~ "建议执行:" ]]; then
            echo
            print -P "%F{cyan}是否执行建议的修复命令? (y/n): %f"
            read -k1 "choice"
            echo
            
            if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
                # 提取建议的命令并执行
                local suggested_cmd=$(echo "$analysis_result" | grep "建议执行:" | sed 's/.*建议执行: *//')
                if [[ -n "$suggested_cmd" ]]; then
                    command_ai_execute_command "$suggested_cmd"
                fi
            fi
        fi
    else
        print -P "%F{red}CommandAI: 无法获取分析结果，请检查配置。%f"
        return 1
    fi
}

# 获取命令历史及其执行状态
command_ai_get_command_history() {
    local count="$1"
    local history_output=""
    
    # 获取最近的命令历史
    local commands=()
    local i=1
    
    while [[ $i -le $count ]]; do
        local cmd=$(fc -ln -$i 2>/dev/null | sed 's/^[[:space:]]*//' | head -1)
        if [[ -n "$cmd" && "$cmd" != "ai fix"* && "$cmd" != "command_ai_"* ]]; then
            commands+=("$cmd")
        fi
        ((i++))
    done
    
    # 构建历史数据格式
    for ((i=1; i<=${#commands[@]}; i++)); do
        local cmd="${commands[$i]}"
        local cmd_status="unknown"
        
        # 分析命令状态
        
        # 尝试通过重新执行命令来获取状态（仅用于分析，不实际执行）
        # 检查命令是否是安全的只读命令
        if [[ "$cmd" =~ ^(pwd|ls|echo|cat|head|tail|grep|find|which|whereis|id|whoami|date|uptime|uname|hostname|ip|ifconfig|ps|top|df|du|free|mount|lsblk|lscpu|lsusb|lspci)($|[[:space:]]) ]]; then
            # 对于安全的只读命令，尝试获取其退出状态
            if eval "$cmd" >/dev/null 2>&1; then
                cmd_status="success"
                # 命令执行成功
            else
                cmd_status="failed"
                # 命令执行失败
            fi
        else
            # 对于其他命令，尝试从历史记录中推断状态
            # 检查是否是已知的失败命令模式
            if [[ "$cmd" =~ ^git ]] && [[ "$cmd" =~ (commmit|oush|aad|checkotu|statsu|branc) ]]; then
                cmd_status="failed"
                # 通过模式匹配判断为失败
            elif [[ "$cmd" == "$COMMAND_AI_LAST_COMMAND" ]] && [[ -n "$COMMAND_AI_LAST_ERROR" ]]; then
                # 如果是最后记录的失败命令
                cmd_status="failed"
                # 记录的失败命令
            else
                # 默认假设成功（因为大多数命令如果失败会被 precmd 钩子捕获）
                cmd_status="assumed_success"
                # 默认假设成功
            fi
        fi
        
        # 尝试获取命令输出
        local cmd_output=""
        
        # 对于安全的只读命令，重新执行以获取输出
        if [[ "$cmd" =~ ^(pwd|ls|echo|cat|head|tail|grep|find|which|whereis|id|whoami|date|uptime|uname|hostname|ip|ifconfig|ps|top|df|du|free|mount|lsblk|lscpu|lsusb|lspci)($|[[:space:]]) ]]; then
            # 重新执行安全命令以获取输出
            cmd_output=$(eval "$cmd" 2>&1)
            local exec_exit_code=$?
            if [[ $exec_exit_code -eq 0 ]]; then
                # 输出获取成功
            else
                # 输出获取失败
                cmd_output="Error: Command failed with exit code $exec_exit_code\n$cmd_output"
            fi
        else
            # 对于其他命令，尝试从缓存或历史中获取输出（如果有的话）
            cmd_output="[Output not available - command not re-executed for safety]"
            # 非安全命令，不重新执行
        fi
        
        # 构建完整的历史记录条目
        history_output+="Command $i: $cmd\nStatus: $cmd_status\nOutput:\n$cmd_output\n\n---\n\n"
    done
    
    echo "$history_output"
}

# 记录反馈
command_ai_record_feedback() {
    local feedback_type="$1"
    local command="$2"
    local query="${COMMAND_AI_LAST_COMMAND:-$command}"
    
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    if [[ -x "$helper_script" ]]; then
        python3 "$helper_script" feedback \
            --query "$query" \
            --command "$command" \
            --feedback-type "$feedback_type" \
            --context "$(command_ai_get_context)" >/dev/null 2>&1
    fi
}

# 获取当前上下文信息
command_ai_get_context() {
    local context=""
    
    # 当前目录
    context+="pwd:$(pwd)"
    
    # Git 仓库信息
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git branch --show-current 2>/dev/null)
        context+="|git:$branch"
    fi
    
    # 系统信息
    context+="|os:$(uname -s)"
    
    # Shell 信息
    context+="|shell:$ZSH_VERSION"
    
    echo "$context"
}

# 切换自动纠错功能
command_ai_toggle_auto_correct() {
    if [[ $COMMAND_AI_CORRECTION_ENABLED -eq 1 ]]; then
        COMMAND_AI_CORRECTION_ENABLED=0
        print -P "%F{yellow}CommandAI: 自动纠错已禁用%f"
    else
        COMMAND_AI_CORRECTION_ENABLED=1
        print -P "%F{green}CommandAI: 自动纠错已启用%f"
    fi
}
