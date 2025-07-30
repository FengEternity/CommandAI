#!/usr/bin/env zsh

# CommandAI 配置管理模块
# 提供配置文件管理功能

# 全局变量
typeset -g COMMAND_AI_CONFIG_EDITOR=${EDITOR:-vim}

# 配置管理主函数
command_ai_config() {
    local action="$1"
    
    case "$action" in
        edit|"")
            command_ai_edit_config
            ;;
        show)
            command_ai_show_config
            ;;
        reset)
            command_ai_reset_config
            ;;
        path)
            echo "$COMMAND_AI_CONFIG"
            ;;
        help|--help|-h)
            command_ai_config_help
            ;;
        *)
            print -P "%F{yellow}未知的配置操作: $action%f"
            command_ai_config_help
            return 1
            ;;
    esac
}

# 编辑配置文件
command_ai_edit_config() {
    if [[ -f "$COMMAND_AI_CONFIG" ]]; then
        print -P "%F{cyan}正在打开配置文件: $COMMAND_AI_CONFIG%f"
        $COMMAND_AI_CONFIG_EDITOR "$COMMAND_AI_CONFIG"
    else
        print -P "%F{yellow}配置文件不存在，正在创建...%f"
        
        # 确保目录存在
        mkdir -p "$(dirname "$COMMAND_AI_CONFIG")"
        
        # 复制示例配置
        if [[ -f "$COMMAND_AI_PLUGIN_DIR/config/config.example.ini" ]]; then
            cp "$COMMAND_AI_PLUGIN_DIR/config/config.example.ini" "$COMMAND_AI_CONFIG"
            print -P "%F{green}✓ 已创建配置文件%f"
            $COMMAND_AI_CONFIG_EDITOR "$COMMAND_AI_CONFIG"
        else
            print -P "%F{red}错误: 示例配置文件不存在%f"
            return 1
        fi
    fi
}

# 显示当前配置
command_ai_show_config() {
    if [[ -f "$COMMAND_AI_CONFIG" ]]; then
        print -P "%F{cyan}当前配置文件内容:%f"
        cat "$COMMAND_AI_CONFIG"
    else
        print -P "%F{yellow}配置文件不存在，请运行 'ai config' 创建%f"
        return 1
    fi
}

# 重置配置文件
command_ai_reset_config() {
    if [[ -f "$COMMAND_AI_CONFIG" ]]; then
        print -P "%F{yellow}确定要重置配置文件吗? 这将删除所有自定义设置。(y/n)%f"
        read -k1 "confirm"
        echo
        
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            # 备份当前配置
            local backup_file="$COMMAND_AI_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
            cp "$COMMAND_AI_CONFIG" "$backup_file"
            
            # 复制示例配置
            if [[ -f "$COMMAND_AI_PLUGIN_DIR/config/config.example.ini" ]]; then
                cp "$COMMAND_AI_PLUGIN_DIR/config/config.example.ini" "$COMMAND_AI_CONFIG"
                print -P "%F{green}✓ 配置已重置，原配置已备份到: $backup_file%f"
            else
                print -P "%F{red}错误: 示例配置文件不存在%f"
                return 1
            fi
        else
            print -P "%F{cyan}操作已取消%f"
        fi
    else
        print -P "%F{yellow}配置文件不存在，请运行 'ai config' 创建%f"
        return 1
    fi
}

# 显示配置帮助
command_ai_config_help() {
    cat << 'EOF'
CommandAI 配置管理

用法:
  ai config           - 编辑配置文件
  ai config show      - 显示当前配置
  ai config reset     - 重置配置到默认值
  ai config path      - 显示配置文件路径
  ai config help      - 显示此帮助信息

配置文件位置: $COMMAND_AI_CONFIG
EOF
}