#!/usr/bin/env zsh

# CommandAI 安全设计模块
# 提供命令安全检查和风险评估功能

# 全局变量
typeset -g COMMAND_AI_SECURITY_ENABLED=1
typeset -g COMMAND_AI_BLACKLIST_FILE="$HOME/.config/command-ai/blacklist.txt"
typeset -g COMMAND_AI_REQUIRE_CONFIRMATION=1
typeset -g COMMAND_AI_DRY_RUN_PREFERRED=1

# 危险命令模式列表
typeset -ga COMMAND_AI_DANGEROUS_PATTERNS=(
    # 文件删除相关
    'rm -rf'
    'rm -r'
    'rm \*'
    'rmdir -r'
    'find.*-delete'
    'find.*-exec rm'
    
    # 磁盘操作
    'dd if='
    'dd of='
    'mkfs'
    'fdisk'
    'parted'
    'gparted'
    'cfdisk'
    
    # 权限修改
    'chmod 777'
    'chmod -R 777'
    'chown -R'
    'chgrp -R'
    
    # 系统级操作
    'sudo rm'
    'sudo dd'
    'sudo mkfs'
    'sudo fdisk'
    'sudo parted'
    'init 0'
    'init 6'
    'shutdown'
    'reboot'
    'halt'
    
    # 网络下载执行
    'curl.*|.*sh'
    'wget.*|.*sh'
    'curl.*|.*bash'
    'wget.*|.*bash'
    'curl.*>.*sh'
    'wget.*>.*sh'
    
    # 重定向到设备
    '> /dev/'
    '>> /dev/'
    
    # 格式化相关
    'format'
    'del /s'
    'rmdir /s'
    
    # 数据库操作
    'DROP DATABASE'
    'DROP TABLE'
    'TRUNCATE'
    'DELETE FROM.*WHERE.*1=1'
    
    # Docker 危险操作
    'docker rm -f'
    'docker rmi -f'
    'docker system prune -a'
    
    # Git 危险操作
    'git reset --hard'
    'git clean -fd'
    'git push --force'
)

# 需要 dry-run 的命令
typeset -ga COMMAND_AI_DRY_RUN_COMMANDS=(
    'rsync'
    'kubectl'
    'terraform'
    'ansible'
    'docker-compose'
)

# 初始化安全模块
command_ai_security_init() {
    # 创建黑名单文件（如果不存在）
    if [[ ! -f "$COMMAND_AI_BLACKLIST_FILE" ]]; then
        mkdir -p "$(dirname "$COMMAND_AI_BLACKLIST_FILE")"
        cat > "$COMMAND_AI_BLACKLIST_FILE" << 'EOF'
# CommandAI 命令黑名单
# 每行一个模式，支持通配符
# 以 # 开头的行为注释

# 示例：
# rm -rf /
# sudo dd if=/dev/zero
# curl * | sh
EOF
    fi
}

# 检查命令是否安全
command_ai_is_command_safe() {
    local command="$1"
    
    if [[ $COMMAND_AI_SECURITY_ENABLED -eq 0 ]]; then
        return 0  # 安全检查被禁用，认为安全
    fi
    
    # 检查黑名单
    if command_ai_check_blacklist "$command"; then
        return 1  # 在黑名单中，不安全
    fi
    
    # 检查危险模式
    if command_ai_check_dangerous_patterns "$command"; then
        return 1  # 匹配危险模式，不安全
    fi
    
    return 0  # 安全
}

# 检查黑名单
command_ai_check_blacklist() {
    local command="$1"
    
    if [[ ! -f "$COMMAND_AI_BLACKLIST_FILE" ]]; then
        return 1  # 黑名单文件不存在，跳过检查
    fi
    
    while IFS= read -r pattern; do
        # 跳过空行和注释
        [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
        
        # 检查模式匹配
        if [[ "$command" =~ $pattern ]]; then
            print -P "%F{red}⚠️  命令被黑名单阻止: $pattern%f" >&2
            return 0  # 匹配黑名单
        fi
    done < "$COMMAND_AI_BLACKLIST_FILE"
    
    return 1  # 不在黑名单中
}

# 检查危险模式
command_ai_check_dangerous_patterns() {
    local command="$1"
    local command_lower="${command:l}"  # 转换为小写
    
    for pattern in "${COMMAND_AI_DANGEROUS_PATTERNS[@]}"; do
        local pattern_lower="${pattern:l}"
        
        if [[ "$command_lower" =~ $pattern_lower ]]; then
            return 0  # 匹配危险模式
        fi
    done
    
    return 1  # 不匹配危险模式
}

# 获取命令风险等级
command_ai_get_risk_level() {
    local command="$1"
    
    # 检查黑名单
    if command_ai_check_blacklist "$command"; then
        echo "BLOCKED"
        return
    fi
    
    # 检查危险模式
    if command_ai_check_dangerous_patterns "$command"; then
        echo "HIGH"
        return
    fi
    
    # 检查中等风险模式
    local medium_risk_patterns=(
        'sudo'
        'su -'
        'chmod'
        'chown'
        'mount'
        'umount'
        'systemctl'
        'service'
    )
    
    local command_lower="${command:l}"
    for pattern in "${medium_risk_patterns[@]}"; do
        if [[ "$command_lower" =~ $pattern ]]; then
            echo "MEDIUM"
            return
        fi
    done
    
    echo "LOW"
}

# 安全执行命令
command_ai_safe_execute() {
    local command="$1"
    local risk_level=$(command_ai_get_risk_level "$command")
    
    case "$risk_level" in
        BLOCKED)
            print -P "%F{red}🚫 命令被安全策略阻止，无法执行%f"
            return 1
            ;;
        HIGH)
            command_ai_handle_high_risk_command "$command"
            ;;
        MEDIUM)
            command_ai_handle_medium_risk_command "$command"
            ;;
        LOW)
            command_ai_execute_command "$command"
            ;;
    esac
}

# 处理高风险命令
command_ai_handle_high_risk_command() {
    local command="$1"
    
    print -P "%F{red}⚠️  高风险命令检测!%f"
    print -P "%F{yellow}命令: $command%f"
    
    # 显示风险说明
    command_ai_explain_risks "$command"
    
    if [[ $COMMAND_AI_REQUIRE_CONFIRMATION -eq 1 ]]; then
        echo
        print -P "%F{red}此命令可能造成严重后果，请仔细确认！%f"
        print -P "%F{cyan}请选择操作:%f"
        print -P "  %F{green}1%f) 我了解风险，继续执行"
        print -P "  %F{yellow}2%f) 尝试生成更安全的替代命令"
        print -P "  %F{blue}3%f) 编辑命令"
        print -P "  %F{red}4%f) 取消执行"
        
        read -k1 "choice?请输入选择 (1-4): "
        echo
        
        case $choice in
            1)
                print -P "%F{yellow}请输入 'I UNDERSTAND THE RISKS' 确认执行:%f"
                read "confirmation"
                if [[ "$confirmation" == "I UNDERSTAND THE RISKS" ]]; then
                    command_ai_execute_command "$command"
                else
                    print -P "%F{red}确认失败，已取消执行%f"
                fi
                ;;
            2)
                command_ai_suggest_safe_alternative "$command"
                ;;
            3)
                command_ai_edit_command "$command"
                ;;
            4)
                print -P "%F{cyan}已取消执行%f"
                ;;
            *)
                print -P "%F{red}无效选择，已取消执行%f"
                ;;
        esac
    else
        print -P "%F{red}安全策略阻止执行此命令%f"
    fi
}

# 处理中等风险命令
command_ai_handle_medium_risk_command() {
    local command="$1"
    
    print -P "%F{yellow}⚠️  中等风险命令%f"
    print -P "%F{cyan}命令: $command%f"
    
    if [[ $COMMAND_AI_REQUIRE_CONFIRMATION -eq 1 ]]; then
        echo
        print -P "%F{cyan}是否继续执行? (y/n)%f"
        read -k1 "confirm"
        echo
        
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            command_ai_execute_command "$command"
        else
            print -P "%F{cyan}已取消执行%f"
        fi
    else
        command_ai_execute_command "$command"
    fi
}

# 解释命令风险
command_ai_explain_risks() {
    local command="$1"
    local command_lower="${command:l}"
    
    print -P "%F{red}潜在风险:%f"
    
    if [[ "$command_lower" =~ "rm -rf" ]]; then
        print -P "  • 可能递归删除大量文件和目录"
        print -P "  • 删除的文件通常无法恢复"
    fi
    
    if [[ "$command_lower" =~ "dd" ]]; then
        print -P "  • 可能覆盖磁盘数据"
        print -P "  • 错误的参数可能导致数据丢失"
    fi
    
    if [[ "$command_lower" =~ "chmod 777" ]]; then
        print -P "  • 将文件权限设置为所有用户可读写执行"
        print -P "  • 可能造成安全漏洞"
    fi
    
    if [[ "$command_lower" =~ "curl.*|.*sh" || "$command_lower" =~ "wget.*|.*sh" ]]; then
        print -P "  • 从网络下载并执行脚本"
        print -P "  • 可能执行恶意代码"
    fi
    
    if [[ "$command_lower" =~ "mkfs" ]]; then
        print -P "  • 格式化文件系统"
        print -P "  • 将清除目标设备上的所有数据"
    fi
}

# 建议安全替代方案
command_ai_suggest_safe_alternative() {
    local command="$1"
    local command_lower="${command:l}"
    
    print -P "%F{cyan}建议的安全替代方案:%f"
    
    if [[ "$command_lower" =~ "rm -rf" ]]; then
        print -P "  • 使用 'ls -la' 先查看要删除的内容"
        print -P "  • 考虑使用 'mv' 移动到回收站目录"
        print -P "  • 使用 'rm -i' 进行交互式删除"
    fi
    
    if [[ "$command_lower" =~ "dd" ]]; then
        print -P "  • 使用 'lsblk' 确认目标设备"
        print -P "  • 添加 'status=progress' 参数监控进度"
        print -P "  • 考虑使用更安全的工具如 'cp' 或 'rsync'"
    fi
    
    if [[ "$command_lower" =~ "chmod 777" ]]; then
        print -P "  • 使用更具体的权限，如 'chmod 755' 或 'chmod 644'"
        print -P "  • 考虑只给特定用户或组权限"
    fi
    
    # 尝试生成更安全的命令
    local safe_cmd=$(command_ai_generate_safe_alternative "$command")
    if [[ -n "$safe_cmd" ]]; then
        print -P "%F{green}建议命令: $safe_cmd%f"
        
        echo
        print -P "%F{cyan}是否使用建议的安全命令? (y/n)%f"
        read -k1 "use_safe"
        echo
        
        if [[ "$use_safe" == "y" || "$use_safe" == "Y" ]]; then
            command_ai_execute_command "$safe_cmd"
        fi
    fi
}

# 生成安全替代命令
command_ai_generate_safe_alternative() {
    local command="$1"
    local command_lower="${command:l}"
    
    # 为 rsync 添加 --dry-run
    if [[ "$command_lower" =~ "rsync" && ! "$command_lower" =~ "--dry-run" ]]; then
        echo "${command} --dry-run"
        return
    fi
    
    # 为 kubectl 添加 --dry-run
    if [[ "$command_lower" =~ "kubectl" && ! "$command_lower" =~ "--dry-run" ]]; then
        echo "${command} --dry-run=client"
        return
    fi
    
    # 为 rm 添加 -i 参数
    if [[ "$command_lower" =~ "rm " && ! "$command_lower" =~ "-i" ]]; then
        echo "${command/rm /rm -i }"
        return
    fi
    
    # 为 dd 添加状态显示
    if [[ "$command_lower" =~ "dd " && ! "$command_lower" =~ "status=" ]]; then
        echo "${command} status=progress"
        return
    fi
}

# 添加到黑名单
command_ai_add_to_blacklist() {
    local pattern="$1"
    
    if [[ -z "$pattern" ]]; then
        print -P "%F{red}请提供要添加到黑名单的模式%f"
        return 1
    fi
    
    echo "$pattern" >> "$COMMAND_AI_BLACKLIST_FILE"
    print -P "%F{green}已添加到黑名单: $pattern%f"
}

# 从黑名单移除
command_ai_remove_from_blacklist() {
    local pattern="$1"
    
    if [[ -z "$pattern" ]]; then
        print -P "%F{red}请提供要从黑名单移除的模式%f"
        return 1
    fi
    
    if [[ -f "$COMMAND_AI_BLACKLIST_FILE" ]]; then
        local temp_file=$(mktemp)
        grep -v "^$pattern$" "$COMMAND_AI_BLACKLIST_FILE" > "$temp_file"
        mv "$temp_file" "$COMMAND_AI_BLACKLIST_FILE"
        print -P "%F{green}已从黑名单移除: $pattern%f"
    fi
}

# 显示黑名单
command_ai_show_blacklist() {
    if [[ -f "$COMMAND_AI_BLACKLIST_FILE" ]]; then
        print -P "%F{cyan}当前黑名单:%f"
        cat "$COMMAND_AI_BLACKLIST_FILE"
    else
        print -P "%F{yellow}黑名单文件不存在%f"
    fi
}

# 安全配置管理
command_ai_security_config() {
    case "$1" in
        enable)
            COMMAND_AI_SECURITY_ENABLED=1
            print -P "%F{green}CommandAI: 安全检查已启用%f"
            ;;
        disable)
            COMMAND_AI_SECURITY_ENABLED=0
            print -P "%F{yellow}CommandAI: 安全检查已禁用%f"
            ;;
        confirmation)
            case "$2" in
                on)
                    COMMAND_AI_REQUIRE_CONFIRMATION=1
                    print -P "%F{green}CommandAI: 危险命令确认已启用%f"
                    ;;
                off)
                    COMMAND_AI_REQUIRE_CONFIRMATION=0
                    print -P "%F{yellow}CommandAI: 危险命令确认已禁用%f"
                    ;;
                *)
                    print -P "%F{cyan}用法: ai security confirmation <on|off>%f"
                    ;;
            esac
            ;;
        blacklist)
            case "$2" in
                add)
                    command_ai_add_to_blacklist "$3"
                    ;;
                remove)
                    command_ai_remove_from_blacklist "$3"
                    ;;
                show)
                    command_ai_show_blacklist
                    ;;
                *)
                    print -P "%F{cyan}用法: ai security blacklist <add|remove|show> [pattern]%f"
                    ;;
            esac
            ;;
        status)
            local security_status="禁用"
            local confirmation_status="禁用"
            [[ $COMMAND_AI_SECURITY_ENABLED -eq 1 ]] && security_status="启用"
            [[ $COMMAND_AI_REQUIRE_CONFIRMATION -eq 1 ]] && confirmation_status="启用"
            
            print -P "%F{cyan}安全检查状态: $security_status%f"
            print -P "%F{cyan}危险命令确认: $confirmation_status%f"
            print -P "%F{cyan}黑名单文件: $COMMAND_AI_BLACKLIST_FILE%f"
            ;;
        *)
            print -P "%F{cyan}用法: ai security <enable|disable|confirmation|blacklist|status>%f"
            ;;
    esac
}

# 初始化安全模块
command_ai_security_init
