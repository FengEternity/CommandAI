#!/usr/bin/env zsh

# CommandAI 自然语言转命令模块
# 将自然语言描述转换为 Shell 命令

# 全局变量
typeset -g COMMAND_AI_NL2CMD_ENABLED=1
typeset -g COMMAND_AI_NL_PREFIX="#"
typeset -g COMMAND_AI_LAST_NL_QUERY=""
typeset -g COMMAND_AI_LAST_GENERATED_CMD=""

# 自然语言转命令主函数
command_ai_nl2cmd() {
    local nl_query="$*"
    
    if [[ $COMMAND_AI_NL2CMD_ENABLED -eq 0 ]]; then
        print -P "%F{yellow}CommandAI: 自然语言转命令功能已禁用%f"
        return 1
    fi
    
    if [[ -z "$nl_query" ]]; then
        print -P "%F{red}CommandAI: 请提供自然语言描述%f"
        print -P "%F{cyan}示例: ai 列出当前目录下的所有 .txt 文件%f"
        return 1
    fi
    
    print -P "%F{cyan}CommandAI: 正在翻译自然语言: $nl_query%f"
    
    # 保存查询用于后续反馈
    COMMAND_AI_LAST_NL_QUERY="$nl_query"
    
    # 获取上下文信息
    local context=$(command_ai_get_context)
    
    # 调用辅助脚本进行翻译
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local generated_cmd
    
    if [[ -x "$helper_script" ]]; then
        # 使用 timeout 命令防止卡死，最多等待 15 秒
        generated_cmd=$(timeout 15s python3 "$helper_script" translate \
            --query "$nl_query" \
            --context "$context" 2>/dev/null)
        
        # 检查是否超时
        if [[ $? -eq 124 ]]; then
            print -P "%F{red}CommandAI: AI 请求超时，请检查网络连接%f"
            return 1
        fi
    fi
    
    if [[ -n "$generated_cmd" ]]; then
        COMMAND_AI_LAST_GENERATED_CMD="$generated_cmd"
        command_ai_present_generated_command "$nl_query" "$generated_cmd"
    else
        print -P "%F{red}CommandAI: 无法翻译自然语言，请检查配置或网络连接%f"
        return 1
    fi
}

# 展示生成的命令
command_ai_present_generated_command() {
    local nl_query="$1"
    local generated_cmd="$2"
    
    # 检查是否为危险命令
    if [[ "$generated_cmd" =~ ^\[DANGER\] ]]; then
        generated_cmd="${generated_cmd#\[DANGER\] }"
        print -P "%F{red}⚠️  警告: 检测到潜在危险命令!%f"
        print -P "%F{yellow}自然语言: $nl_query%f"
        print -P "%F{red}生成命令: $generated_cmd%f"
        print -P "%F{yellow}请仔细确认后再执行！%f"
        
        echo
        print -P "%F{cyan}请选择操作:%f"
        print -P "  %F{green}1%f) 执行命令"
        print -P "  %F{yellow}2%f) 编辑命令"
        print -P "  %F{blue}3%f) 显示详细说明"
        print -P "  %F{red}4%f) 取消"
        
        read -k1 "choice?请输入选择 (1-4): "
        echo
        
        case $choice in
            1)
                print -P "%F{yellow}请再次确认执行危险命令 (输入 'yes' 确认): %f"
                read "confirm"
                if [[ "$confirm" == "yes" ]]; then
                    command_ai_execute_generated_command "$generated_cmd"
                else
                    print -P "%F{cyan}已取消执行%f"
                fi
                ;;
            2)
                command_ai_edit_generated_command "$generated_cmd"
                ;;
            3)
                command_ai_explain_command "$generated_cmd"
                ;;
            4)
                print -P "%F{cyan}已取消%f"
                ;;
            *)
                print -P "%F{red}无效选择%f"
                ;;
        esac
    else
        print -P "%F{green}自然语言: $nl_query%f"
        print -P "%F{cyan}生成命令: $generated_cmd%f"
        
        echo
        print -P "%F{cyan}请选择操作:%f"
        print -P "  %F{green}1%f) 执行命令"
        print -P "  %F{yellow}2%f) 编辑命令"
        print -P "  %F{blue}3%f) 显示详细说明"
        print -P "  %F{red}4%f) 取消"
        
        read -k1 "choice?请输入选择 (1-4): "
        echo
        
        case $choice in
            1)
                command_ai_execute_generated_command "$generated_cmd"
                ;;
            2)
                command_ai_edit_generated_command "$generated_cmd"
                ;;
            3)
                command_ai_explain_command "$generated_cmd"
                ;;
            4)
                print -P "%F{cyan}已取消%f"
                ;;
            *)
                print -P "%F{red}无效选择%f"
                ;;
        esac
    fi
}

# 执行生成的命令
command_ai_execute_generated_command() {
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
        command_ai_record_nl_feedback "good" "$cmd"
    else
        print -P "%F{red}✗ 命令执行失败 (退出码: $exit_code)%f"
        command_ai_record_nl_feedback "bad" "$cmd"
        
        # 提供重新生成的选项
        echo
        print -P "%F{cyan}是否需要重新生成命令? (y/n)%f"
        read -k1 "retry"
        echo
        if [[ "$retry" == "y" || "$retry" == "Y" ]]; then
            command_ai_nl2cmd "$COMMAND_AI_LAST_NL_QUERY"
        fi
    fi
}

# 编辑生成的命令
command_ai_edit_generated_command() {
    local cmd="$1"
    
    # 将命令放入输入缓冲区供用户编辑
    BUFFER="$cmd"
    CURSOR=${#BUFFER}
    
    print -P "%F{cyan}命令已放入输入缓冲区，请编辑后按 Enter 执行%f"
}

# 解释命令
command_ai_explain_command() {
    local cmd="$1"
    
    print -P "%F{cyan}命令详细说明:%f"
    print -P "%F{white}$cmd%f"
    echo
    
    # 分解命令组件
    local components=("${(@s/ /)cmd}")
    local main_cmd="${components[1]}"
    
    # 提供基本说明
    case "$main_cmd" in
        ls)
            print -P "%F{yellow}ls: 列出目录内容%f"
            ;;
        find)
            print -P "%F{yellow}find: 在目录树中搜索文件和目录%f"
            ;;
        grep)
            print -P "%F{yellow}grep: 在文件中搜索文本模式%f"
            ;;
        awk)
            print -P "%F{yellow}awk: 文本处理工具%f"
            ;;
        sed)
            print -P "%F{yellow}sed: 流编辑器，用于过滤和转换文本%f"
            ;;
        curl)
            print -P "%F{yellow}curl: 传输数据的命令行工具%f"
            ;;
        wget)
            print -P "%F{yellow}wget: 从网络下载文件%f"
            ;;
        docker)
            print -P "%F{yellow}docker: 容器管理工具%f"
            ;;
        git)
            print -P "%F{yellow}git: 版本控制系统%f"
            ;;
        *)
            print -P "%F{yellow}$main_cmd: 命令行工具%f"
            ;;
    esac
    
    # 分析参数
    if [[ ${#components[@]} -gt 1 ]]; then
        print -P "%F{cyan}参数分析:%f"
        for ((i=2; i<=${#components[@]}; i++)); do
            local arg="${components[$i]}"
            if [[ "$arg" =~ ^--.* ]]; then
                print -P "  %F{green}$arg%f: 长选项"
            elif [[ "$arg" =~ ^-.* ]]; then
                print -P "  %F{green}$arg%f: 短选项"
            else
                print -P "  %F{blue}$arg%f: 参数值"
            fi
        done
    fi
    
    echo
    print -P "%F{cyan}按任意键继续...%f"
    read -k1
}

# 记录自然语言转换反馈
command_ai_record_nl_feedback() {
    local feedback_type="$1"
    local command="$2"
    local query="$COMMAND_AI_LAST_NL_QUERY"
    
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    if [[ -x "$helper_script" ]]; then
        python3 "$helper_script" feedback \
            --query "$query" \
            --command "$command" \
            --feedback-type "$feedback_type" \
            --context "$(command_ai_get_context)" >/dev/null 2>&1
    fi
}

# 处理带前缀的自然语言输入
command_ai_process_nl_prefix() {
    local buffer="$BUFFER"
    
    # 检查是否以自然语言前缀开始
    if [[ "$buffer" =~ ^${COMMAND_AI_NL_PREFIX}(.+)$ ]]; then
        local nl_query="${match[1]# }"
        
        if [[ -n "$nl_query" ]]; then
            # 清空当前缓冲区
            BUFFER=""
            CURSOR=0
            
            # 翻译自然语言
            command_ai_translate_nl_inline "$nl_query"
        fi
    fi
}

# 内联翻译自然语言
command_ai_translate_nl_inline() {
    local nl_query="$1"
    
    print -P "\n%F{cyan}CommandAI: 翻译自然语言: $nl_query%f"
    
    local context=$(command_ai_get_context)
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    local generated_cmd
    
    if [[ -x "$helper_script" ]]; then
        # 使用 timeout 命令防止卡死，最多等待 15 秒
        generated_cmd=$(timeout 15s python3 "$helper_script" translate \
            --query "$nl_query" \
            --context "$context" 2>/dev/null)
        
        # 检查是否超时
        if [[ $? -eq 124 ]]; then
            print -P "%F{red}CommandAI: AI 请求超时，请检查网络连接%f"
            return 1
        fi
    fi
    
    if [[ -n "$generated_cmd" ]]; then
        # 移除危险标签（如果存在）
        local clean_cmd="$generated_cmd"
        if [[ "$generated_cmd" =~ ^\[DANGER\] ]]; then
            clean_cmd="${generated_cmd#\[DANGER\] }"
            print -P "%F{red}⚠️  警告: 潜在危险命令%f"
        fi
        
        # 将命令放入缓冲区
        BUFFER="$clean_cmd"
        CURSOR=${#BUFFER}
        
        print -P "%F{green}✓ 已生成命令: $clean_cmd%f"
        print -P "%F{cyan}请检查命令后按 Enter 执行%f"
        
        # 保存用于反馈
        COMMAND_AI_LAST_NL_QUERY="$nl_query"
        COMMAND_AI_LAST_GENERATED_CMD="$clean_cmd"
    else
        print -P "%F{red}CommandAI: 翻译失败%f"
    fi
}

# 注册 ZLE 函数
zle -N command_ai_process_nl_prefix

# 自然语言转换配置管理
command_ai_nl2cmd_config() {
    case "$1" in
        enable)
            COMMAND_AI_NL2CMD_ENABLED=1
            print -P "%F{green}CommandAI: 自然语言转命令已启用%f"
            ;;
        disable)
            COMMAND_AI_NL2CMD_ENABLED=0
            print -P "%F{yellow}CommandAI: 自然语言转命令已禁用%f"
            ;;
        prefix)
            if [[ -n "$2" ]]; then
                COMMAND_AI_NL_PREFIX="$2"
                print -P "%F{cyan}CommandAI: 自然语言前缀设置为 '$2'%f"
            else
                print -P "%F{red}CommandAI: 请提供前缀%f"
            fi
            ;;
        status)
            local status="禁用"
            [[ $COMMAND_AI_NL2CMD_ENABLED -eq 1 ]] && status="启用"
            print -P "%F{cyan}自然语言转命令状态: $status%f"
            print -P "%F{cyan}自然语言前缀: '$COMMAND_AI_NL_PREFIX'%f"
            ;;
        *)
            print -P "%F{cyan}用法: ai nl2cmd <enable|disable|prefix|status> [value]%f"
            ;;
    esac
}

# 快速自然语言转换
command_ai_quick_nl() {
    local nl_query="$*"
    
    if [[ -z "$nl_query" ]]; then
        print -P "%F{cyan}请输入自然语言描述:%f"
        read "nl_query"
    fi
    
    if [[ -n "$nl_query" ]]; then
        command_ai_translate_nl_inline "$nl_query"
    fi
}

# 批量自然语言转换
command_ai_batch_nl() {
    print -P "%F{cyan}批量自然语言转命令模式 (输入 'quit' 退出):%f"
    
    while true; do
        print -P "%F{green}请输入自然语言描述:%f"
        read "nl_query"
        
        if [[ "$nl_query" == "quit" || "$nl_query" == "exit" ]]; then
            break
        fi
        
        if [[ -n "$nl_query" ]]; then
            command_ai_nl2cmd "$nl_query"
            echo
        fi
    done
    
    print -P "%F{cyan}已退出批量模式%f"
}
