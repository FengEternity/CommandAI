#!/usr/bin/env zsh

# CommandAI 命令缓存模块
# 提供智能缓存管理功能

# 全局变量
typeset -g COMMAND_AI_CACHE_ENABLED=1
typeset -g COMMAND_AI_CACHE_MAX_SIZE=1000
typeset -g COMMAND_AI_CACHE_TTL=86400  # 24小时
typeset -g COMMAND_AI_CACHE_DB="$COMMAND_AI_CACHE_DIR/cache.db"

# 缓存管理主函数
command_ai_cache_management() {
    case "$1" in
        clear)
            command_ai_clear_cache "$2"
            ;;
        stats)
            command_ai_show_cache_stats
            ;;
        optimize)
            command_ai_optimize_cache
            ;;
        export)
            command_ai_export_cache "$2"
            ;;
        import)
            command_ai_import_cache "$2"
            ;;
        config)
            command_ai_cache_config "${@:2}"
            ;;
        *)
            command_ai_show_cache_help
            ;;
    esac
}

# 清空缓存
command_ai_clear_cache() {
    local cache_type="$1"
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    
    if [[ -x "$helper_script" ]]; then
        case "$cache_type" in
            all|"")
                python3 "$helper_script" cache --cache-action clear >/dev/null 2>&1
                print -P "%F{green}✓ 所有缓存已清空%f"
                ;;
            commands)
                # 清空命令缓存
                if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
                    sqlite3 "$COMMAND_AI_CACHE_DB" "DELETE FROM command_cache;" 2>/dev/null
                    print -P "%F{green}✓ 命令缓存已清空%f"
                fi
                ;;
            feedback)
                # 清空反馈缓存
                if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
                    sqlite3 "$COMMAND_AI_CACHE_DB" "DELETE FROM feedback;" 2>/dev/null
                    print -P "%F{green}✓ 反馈缓存已清空%f"
                fi
                ;;
            old)
                command_ai_clear_old_cache
                ;;
            *)
                print -P "%F{red}无效的缓存类型: $cache_type%f"
                print -P "%F{cyan}可用类型: all, commands, feedback, old%f"
                ;;
        esac
    else
        print -P "%F{red}缓存助手脚本不可用%f"
    fi
}

# 清空过期缓存
command_ai_clear_old_cache() {
    if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
        local cutoff_date=$(date -d "$COMMAND_AI_CACHE_TTL seconds ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        
        if [[ -n "$cutoff_date" ]]; then
            local deleted_count=$(sqlite3 "$COMMAND_AI_CACHE_DB" \
                "DELETE FROM command_cache WHERE created_at < '$cutoff_date'; SELECT changes();" 2>/dev/null | tail -1)
            
            print -P "%F{green}✓ 已清理 $deleted_count 条过期缓存%f"
        else
            print -P "%F{yellow}无法计算过期时间%f"
        fi
    fi
}

# 显示缓存统计
command_ai_show_cache_stats() {
    local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
    
    if [[ -x "$helper_script" ]]; then
        local stats_json=$(python3 "$helper_script" cache --cache-action stats 2>/dev/null)
        
        if [[ -n "$stats_json" ]]; then
            # 解析统计信息
            local cache_entries=$(echo "$stats_json" | grep -o '"cache_entries": [0-9]*' | cut -d: -f2 | tr -d ' ')
            local feedback_entries=$(echo "$stats_json" | grep -o '"feedback_entries": [0-9]*' | cut -d: -f2 | tr -d ' ')
            local success_total=$(echo "$stats_json" | grep -o '"success_total": [0-9]*' | cut -d: -f2 | tr -d ' ')
            local failure_total=$(echo "$stats_json" | grep -o '"failure_total": [0-9]*' | cut -d: -f2 | tr -d ' ')
            
            print -P "%F{cyan}=== CommandAI 缓存统计 ===%f"
            print -P "%F{green}命令缓存条目: ${cache_entries:-0}%f"
            print -P "%F{green}反馈记录条目: ${feedback_entries:-0}%f"
            print -P "%F{green}成功执行次数: ${success_total:-0}%f"
            print -P "%F{red}失败执行次数: ${failure_total:-0}%f"
            
            # 计算成功率
            local total_executions=$((${success_total:-0} + ${failure_total:-0}))
            if [[ $total_executions -gt 0 ]]; then
                local success_rate=$(( ${success_total:-0} * 100 / total_executions ))
                print -P "%F{cyan}成功率: ${success_rate}%%f"
            fi
            
            # 显示缓存文件大小
            if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
                local cache_size=$(du -h "$COMMAND_AI_CACHE_DB" 2>/dev/null | cut -f1)
                print -P "%F{yellow}缓存文件大小: ${cache_size:-未知}%f"
            fi
            
            # 显示最近使用的缓存
            command_ai_show_recent_cache
        else
            print -P "%F{red}无法获取缓存统计信息%f"
        fi
    else
        print -P "%F{red}缓存助手脚本不可用%f"
    fi
}

# 显示最近使用的缓存
command_ai_show_recent_cache() {
    if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
        print -P "\n%F{cyan}最近使用的缓存 (前10条):%f"
        
        local recent_cache=$(sqlite3 "$COMMAND_AI_CACHE_DB" \
            "SELECT query, command, success_count, last_used 
             FROM command_cache 
             ORDER BY last_used DESC 
             LIMIT 10;" 2>/dev/null)
        
        if [[ -n "$recent_cache" ]]; then
            local i=1
            while IFS='|' read -r query command success_count last_used; do
                print -P "%F{green}$i.%f %F{white}$query%f"
                print -P "   %F{cyan}→ $command%f %F{yellow}(成功: $success_count 次)%f"
                print -P "   %F{gray}最后使用: $last_used%f"
                ((i++))
            done <<< "$recent_cache"
        else
            print -P "%F{yellow}暂无缓存记录%f"
        fi
    fi
}

# 优化缓存
command_ai_optimize_cache() {
    if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
        print -P "%F{cyan}正在优化缓存...%f"
        
        # 删除失败次数过多的缓存
        local deleted_bad=$(sqlite3 "$COMMAND_AI_CACHE_DB" \
            "DELETE FROM command_cache WHERE failure_count > success_count AND failure_count > 3; SELECT changes();" 2>/dev/null | tail -1)
        
        # 删除长时间未使用的缓存
        local cutoff_date=$(date -d "30 days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        local deleted_old=0
        if [[ -n "$cutoff_date" ]]; then
            deleted_old=$(sqlite3 "$COMMAND_AI_CACHE_DB" \
                "DELETE FROM command_cache WHERE last_used < '$cutoff_date' AND success_count = 0; SELECT changes();" 2>/dev/null | tail -1)
        fi
        
        # 限制缓存大小
        local total_count=$(sqlite3 "$COMMAND_AI_CACHE_DB" "SELECT COUNT(*) FROM command_cache;" 2>/dev/null)
        local deleted_excess=0
        
        if [[ $total_count -gt $COMMAND_AI_CACHE_MAX_SIZE ]]; then
            local excess=$((total_count - COMMAND_AI_CACHE_MAX_SIZE))
            deleted_excess=$(sqlite3 "$COMMAND_AI_CACHE_DB" \
                "DELETE FROM command_cache WHERE id IN (
                    SELECT id FROM command_cache 
                    ORDER BY success_count ASC, last_used ASC 
                    LIMIT $excess
                ); SELECT changes();" 2>/dev/null | tail -1)
        fi
        
        # 压缩数据库
        sqlite3 "$COMMAND_AI_CACHE_DB" "VACUUM;" 2>/dev/null
        
        print -P "%F{green}✓ 缓存优化完成%f"
        print -P "  删除失效缓存: ${deleted_bad:-0} 条"
        print -P "  删除过期缓存: ${deleted_old:-0} 条"
        print -P "  删除多余缓存: ${deleted_excess:-0} 条"
    else
        print -P "%F{yellow}缓存数据库不存在%f"
    fi
}

# 导出缓存
command_ai_export_cache() {
    local export_file="$1"
    
    if [[ -z "$export_file" ]]; then
        export_file="$HOME/command-ai-cache-$(date +%Y%m%d-%H%M%S).json"
    fi
    
    if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
        print -P "%F{cyan}正在导出缓存到: $export_file%f"
        
        # 导出为 JSON 格式
        sqlite3 "$COMMAND_AI_CACHE_DB" \
            "SELECT json_group_array(
                json_object(
                    'query', query,
                    'command', command,
                    'context', context,
                    'success_count', success_count,
                    'failure_count', failure_count,
                    'last_used', last_used,
                    'created_at', created_at
                )
            ) FROM command_cache;" 2>/dev/null > "$export_file"
        
        if [[ $? -eq 0 ]]; then
            print -P "%F{green}✓ 缓存导出成功%f"
        else
            print -P "%F{red}✗ 缓存导出失败%f"
        fi
    else
        print -P "%F{yellow}缓存数据库不存在%f"
    fi
}

# 导入缓存
command_ai_import_cache() {
    local import_file="$1"
    
    if [[ -z "$import_file" ]]; then
        print -P "%F{red}请指定要导入的文件%f"
        return 1
    fi
    
    if [[ ! -f "$import_file" ]]; then
        print -P "%F{red}导入文件不存在: $import_file%f"
        return 1
    fi
    
    print -P "%F{cyan}正在导入缓存从: $import_file%f"
    
    # 这里需要更复杂的 JSON 解析，暂时提供基本框架
    print -P "%F{yellow}缓存导入功能正在开发中%f"
}

# 缓存配置管理
command_ai_cache_config() {
    case "$1" in
        enable)
            COMMAND_AI_CACHE_ENABLED=1
            print -P "%F{green}CommandAI: 缓存已启用%f"
            ;;
        disable)
            COMMAND_AI_CACHE_ENABLED=0
            print -P "%F{yellow}CommandAI: 缓存已禁用%f"
            ;;
        max-size)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                COMMAND_AI_CACHE_MAX_SIZE="$2"
                print -P "%F{cyan}CommandAI: 缓存最大大小设置为 $2%f"
            else
                print -P "%F{red}请提供有效的数字%f"
            fi
            ;;
        ttl)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                COMMAND_AI_CACHE_TTL="$2"
                print -P "%F{cyan}CommandAI: 缓存TTL设置为 $2 秒%f"
            else
                print -P "%F{red}请提供有效的秒数%f"
            fi
            ;;
        status)
            local cache_status="禁用"
            [[ $COMMAND_AI_CACHE_ENABLED -eq 1 ]] && cache_status="启用"
            
            print -P "%F{cyan}缓存状态: $cache_status%f"
            print -P "%F{cyan}最大缓存大小: $COMMAND_AI_CACHE_MAX_SIZE%f"
            print -P "%F{cyan}缓存TTL: $COMMAND_AI_CACHE_TTL 秒%f"
            print -P "%F{cyan}缓存数据库: $COMMAND_AI_CACHE_DB%f"
            ;;
        *)
            print -P "%F{cyan}用法: ai cache config <enable|disable|max-size|ttl|status> [value]%f"
            ;;
    esac
}

# 反馈管理
command_ai_feedback() {
    local feedback_type="$1"
    local target_command="$2"
    
    case "$feedback_type" in
        good|bad)
            if [[ -n "$COMMAND_AI_LAST_GENERATED_CMD" ]]; then
                local query="${COMMAND_AI_LAST_NL_QUERY:-$COMMAND_AI_LAST_COMMAND}"
                local command="${target_command:-$COMMAND_AI_LAST_GENERATED_CMD}"
                
                local helper_script="$COMMAND_AI_PLUGIN_DIR/bin/command-ai-helper"
                if [[ -x "$helper_script" ]]; then
                    python3 "$helper_script" feedback \
                        --query "$query" \
                        --command "$command" \
                        --feedback-type "$feedback_type" \
                        --context "$(command_ai_get_context)" >/dev/null 2>&1
                    
                    print -P "%F{green}✓ 反馈已记录: $feedback_type%f"
                else
                    print -P "%F{red}反馈助手脚本不可用%f"
                fi
            else
                print -P "%F{yellow}没有可反馈的命令%f"
            fi
            ;;
        show)
            command_ai_show_recent_feedback
            ;;
        *)
            print -P "%F{cyan}用法: ai feedback <good|bad|show> [command]%f"
            ;;
    esac
}

# 显示最近的反馈
command_ai_show_recent_feedback() {
    if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
        print -P "%F{cyan}最近的反馈记录 (前10条):%f"
        
        local recent_feedback=$(sqlite3 "$COMMAND_AI_CACHE_DB" \
            "SELECT command, feedback, timestamp 
             FROM feedback 
             ORDER BY timestamp DESC 
             LIMIT 10;" 2>/dev/null)
        
        if [[ -n "$recent_feedback" ]]; then
            local i=1
            while IFS='|' read -r command feedback timestamp; do
                local color="%F{green}"
                [[ "$feedback" == "bad" ]] && color="%F{red}"
                
                print -P "%F{cyan}$i.%f %F{white}$command%f"
                print -P "   ${color}反馈: $feedback%f %F{gray}($timestamp)%f"
                ((i++))
            done <<< "$recent_feedback"
        else
            print -P "%F{yellow}暂无反馈记录%f"
        fi
    fi
}

# 显示缓存帮助
command_ai_show_cache_help() {
    cat << 'EOF'
CommandAI 缓存管理

用法:
  ai cache clear [type]    - 清空缓存 (all/commands/feedback/old)
  ai cache stats           - 显示缓存统计信息
  ai cache optimize        - 优化缓存性能
  ai cache export [file]   - 导出缓存到文件
  ai cache import <file>   - 从文件导入缓存
  ai cache config <option> - 配置缓存设置

配置选项:
  enable/disable          - 启用/禁用缓存
  max-size <number>       - 设置最大缓存条目数
  ttl <seconds>           - 设置缓存生存时间
  status                  - 显示当前配置

示例:
  ai cache clear old
  ai cache config max-size 500
  ai cache export ~/my-cache.json
EOF
}

# 自动缓存清理任务
command_ai_auto_cache_cleanup() {
    # 检查是否需要清理
    if [[ -f "$COMMAND_AI_CACHE_DB" ]]; then
        local cache_count=$(sqlite3 "$COMMAND_AI_CACHE_DB" "SELECT COUNT(*) FROM command_cache;" 2>/dev/null)
        
        # 如果缓存条目超过最大限制的120%，自动清理
        local cleanup_threshold=$((COMMAND_AI_CACHE_MAX_SIZE * 120 / 100))
        
        if [[ $cache_count -gt $cleanup_threshold ]]; then
            print -P "%F{yellow}CommandAI: 缓存条目过多，正在自动清理...%f"
            command_ai_optimize_cache >/dev/null 2>&1
        fi
    fi
}

# 在插件加载时执行自动清理
command_ai_auto_cache_cleanup
