#!/bin/bash

# CommandAI 安装脚本
# 自动安装和配置 CommandAI Zsh 插件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置变量
PLUGIN_NAME="command-ai"
INSTALL_DIR="$HOME/.oh-my-zsh/custom/plugins/$PLUGIN_NAME"
CONFIG_DIR="$HOME/.config/command-ai"
CACHE_DIR="$HOME/.cache/command-ai"
BACKUP_DIR="$HOME/.command-ai-backup-$(date +%Y%m%d-%H%M%S)"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_info() {
    print_message "$CYAN" "ℹ️  $1"
}

print_success() {
    print_message "$GREEN" "✅ $1"
}

print_warning() {
    print_message "$YELLOW" "⚠️  $1"
}

print_error() {
    print_message "$RED" "❌ $1"
}

# 检查依赖
check_dependencies() {
    print_info "检查系统依赖..."
    
    local missing_deps=()
    
    # 检查 Zsh
    if ! command -v zsh &> /dev/null; then
        missing_deps+=("zsh")
    fi
    
    # 检查 Python3
    if ! command -v python3 &> /dev/null; then
        missing_deps+=("python3")
    fi
    
    # 检查 pip3
    if ! command -v pip3 &> /dev/null; then
        missing_deps+=("python3-pip")
    fi
    
    # 检查 sqlite3
    if ! command -v sqlite3 &> /dev/null; then
        missing_deps+=("sqlite3")
    fi
    
    # 检查 curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "缺少以下依赖: ${missing_deps[*]}"
        print_info "请先安装缺少的依赖，然后重新运行安装脚本"
        
        # 提供安装建议
        if command -v apt-get &> /dev/null; then
            print_info "Ubuntu/Debian 系统请运行: sudo apt-get install ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            print_info "CentOS/RHEL 系统请运行: sudo yum install ${missing_deps[*]}"
        elif command -v brew &> /dev/null; then
            print_info "macOS 系统请运行: brew install ${missing_deps[*]}"
        fi
        
        exit 1
    fi
    
    print_success "所有依赖检查通过"
}

# 检查 Python 包
check_python_packages() {
    print_info "检查 Python 包..."
    
    local required_packages=("requests" "configparser")
    local missing_packages=()
    
    for package in "${required_packages[@]}"; do
        if ! python3 -c "import $package" &> /dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -ne 0 ]; then
        print_warning "缺少 Python 包: ${missing_packages[*]}"
        print_info "正在安装缺少的 Python 包..."
        
        for package in "${missing_packages[@]}"; do
            if pip3 install "$package" --user; then
                print_success "已安装 $package"
            else
                print_error "安装 $package 失败"
                exit 1
            fi
        done
    fi
    
    print_success "Python 包检查完成"
}

# 检查 Zsh 和 Oh My Zsh
check_zsh_setup() {
    print_info "检查 Zsh 配置..."
    
    # 检查当前 shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        print_warning "当前 shell 不是 Zsh"
        print_info "建议将 Zsh 设置为默认 shell: chsh -s $(which zsh)"
    fi
    
    # 检查 Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_warning "未检测到 Oh My Zsh"
        print_info "CommandAI 可以在没有 Oh My Zsh 的情况下工作"
        print_info "如果您想使用 Oh My Zsh，请先安装: sh -c \"\$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
        
        # 询问是否继续
        read -p "是否继续安装? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "安装已取消"
            exit 0
        fi
        
        # 设置为手动安装模式
        INSTALL_DIR="$HOME/.command-ai"
    fi
    
    print_success "Zsh 配置检查完成"
}

# 备份现有配置
backup_existing_config() {
    print_info "备份现有配置..."
    
    local need_backup=false
    
    # 检查是否需要备份
    if [ -d "$INSTALL_DIR" ] || [ -d "$CONFIG_DIR" ] || [ -d "$CACHE_DIR" ]; then
        need_backup=true
    fi
    
    if [ "$need_backup" = true ]; then
        print_warning "检测到现有的 CommandAI 配置"
        
        # 询问是否备份
        read -p "是否备份现有配置? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$BACKUP_DIR"
            
            [ -d "$INSTALL_DIR" ] && cp -r "$INSTALL_DIR" "$BACKUP_DIR/plugin"
            [ -d "$CONFIG_DIR" ] && cp -r "$CONFIG_DIR" "$BACKUP_DIR/config"
            [ -d "$CACHE_DIR" ] && cp -r "$CACHE_DIR" "$BACKUP_DIR/cache"
            
            print_success "配置已备份到: $BACKUP_DIR"
        fi
    fi
}

# 安装插件文件
install_plugin_files() {
    print_info "安装插件文件..."
    
    # 创建安装目录
    mkdir -p "$INSTALL_DIR"
    
    # 获取项目根目录（脚本在 scripts/ 子目录中）
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
    
    # 复制插件文件
    if [ -f "$SCRIPT_DIR/command-ai.plugin.zsh" ]; then
        cp "$SCRIPT_DIR/command-ai.plugin.zsh" "$INSTALL_DIR/"
        print_success "已复制主插件文件"
    else
        print_error "找不到主插件文件"
        exit 1
    fi
    
    # 复制模块文件
    if [ -d "$SCRIPT_DIR/modules" ]; then
        cp -r "$SCRIPT_DIR/modules" "$INSTALL_DIR/"
        print_success "已复制模块文件"
    else
        print_error "找不到模块目录"
        exit 1
    fi
    
    # 复制辅助脚本
    if [ -d "$SCRIPT_DIR/bin" ]; then
        cp -r "$SCRIPT_DIR/bin" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/bin/command-ai-helper"
        print_success "已复制辅助脚本"
    else
        print_error "找不到 bin 目录"
        exit 1
    fi
    
    # 复制补全文件
    if [ -d "$SCRIPT_DIR/completions" ]; then
        cp -r "$SCRIPT_DIR/completions" "$INSTALL_DIR/"
        print_success "已复制补全文件"
    else
        print_error "找不到补全目录"
        exit 1
    fi
    
    print_success "插件文件安装完成"
}

# 安装配置文件
install_config_files() {
    print_info "安装配置文件..."
    
    # 创建配置目录
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CACHE_DIR"
    
    # 复制配置文件模板
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
    
    if [ -f "$SCRIPT_DIR/config/config.example.ini" ]; then
        if [ ! -f "$CONFIG_DIR/config.ini" ]; then
            cp "$SCRIPT_DIR/config/config.example.ini" "$CONFIG_DIR/config.ini"
            print_success "已创建配置文件: $CONFIG_DIR/config.ini"
        else
            print_warning "配置文件已存在，跳过创建"
        fi
    else
        print_error "找不到配置文件模板"
        exit 1
    fi
    
    # 复制自定义 prompt 示例文件
    if [ -f "$SCRIPT_DIR/config/custom-prompt-example.ini" ]; then
        if [ ! -f "$CONFIG_DIR/custom-prompt-example.ini" ]; then
            cp "$SCRIPT_DIR/config/custom-prompt-example.ini" "$CONFIG_DIR/custom-prompt-example.ini"
            print_success "已复制自定义 prompt 示例文件"
        fi
    fi
    
    # 复制 Markdown 格式的自定义 prompt 配置文件
    if [ -f "$SCRIPT_DIR/config/custom-prompts.md" ]; then
        if [ ! -f "$CONFIG_DIR/custom-prompts.md" ]; then
            cp "$SCRIPT_DIR/config/custom-prompts.md" "$CONFIG_DIR/custom-prompts.md"
            print_success "已复制 Markdown 格式的自定义 prompt 配置文件"
        fi
    fi
    
    # 创建黑名单文件
    if [ ! -f "$CONFIG_DIR/blacklist.txt" ]; then
        cat > "$CONFIG_DIR/blacklist.txt" << 'EOF'
# CommandAI 命令黑名单
# 每行一个模式，支持通配符
# 以 # 开头的行为注释

# 示例：
# rm -rf /
# sudo dd if=/dev/zero
# curl * | sh
EOF
        print_success "已创建黑名单文件"
    fi
    
    print_success "配置文件安装完成"
}

# 配置 Zsh
configure_zsh() {
    print_info "配置 Zsh..."
    
    local zshrc="$HOME/.zshrc"
    local plugin_line=""
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        # Oh My Zsh 模式
        plugin_line="plugins=(... command-ai)"
        
        # 检查是否已经添加到插件列表
        if grep -q "command-ai" "$zshrc" 2>/dev/null; then
            print_warning "CommandAI 插件已在 .zshrc 中配置"
        else
            print_info "请手动将 'command-ai' 添加到 .zshrc 的 plugins 列表中"
            print_info "例如: plugins=(git command-ai)"
        fi
    else
        # 手动模式
        plugin_line="source $INSTALL_DIR/command-ai.plugin.zsh"
        
        # 检查是否已经添加
        if grep -q "command-ai.plugin.zsh" "$zshrc" 2>/dev/null; then
            print_warning "CommandAI 插件已在 .zshrc 中配置"
        else
            # 添加到 .zshrc
            echo "" >> "$zshrc"
            echo "# CommandAI Plugin" >> "$zshrc"
            echo "$plugin_line" >> "$zshrc"
            print_success "已添加插件配置到 .zshrc"
        fi
    fi
    
    print_success "Zsh 配置完成"
}

# 配置 API Key
configure_api_key() {
    print_info "配置 API Key..."
    
    local config_file="$CONFIG_DIR/config.ini"
    
    # 检查是否已配置
    if grep -q "your_api_key_here" "$config_file" 2>/dev/null; then
        print_warning "检测到默认 API Key，需要配置"
        
        echo
        print_info "CommandAI 需要 AI API Key 才能正常工作"
        print_info "支持的 API 提供商:"
        print_info "  1. OpenAI (https://platform.openai.com/api-keys)"
        print_info "  2. Azure OpenAI"
        print_info "  3. 其他兼容 OpenAI API 的服务"
        print_info "  4. 本地模型 (如 Ollama)"
        
        echo
        read -p "是否现在配置 API Key? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            read -p "请输入您的 API Key: " api_key
            
            if [ -n "$api_key" ]; then
                # 替换配置文件中的 API Key
                if command -v sed &> /dev/null; then
                    sed -i.bak "s/your_api_key_here/$api_key/" "$config_file"
                    rm -f "$config_file.bak"
                    print_success "API Key 配置完成"
                else
                    print_warning "请手动编辑 $config_file 文件，将 'your_api_key_here' 替换为您的 API Key"
                fi
            else
                print_warning "未输入 API Key，请稍后手动配置"
            fi
        else
            print_warning "跳过 API Key 配置，请稍后手动配置"
        fi
    else
        print_success "API Key 已配置"
    fi
}

# 验证安装
verify_installation() {
    print_info "验证安装..."
    
    local errors=()
    
    # 检查插件文件
    if [ ! -f "$INSTALL_DIR/command-ai.plugin.zsh" ]; then
        errors+=("主插件文件缺失")
    fi
    
    if [ ! -d "$INSTALL_DIR/modules" ]; then
        errors+=("模块目录缺失")
    fi
    
    if [ ! -x "$INSTALL_DIR/bin/command-ai-helper" ]; then
        errors+=("辅助脚本缺失或不可执行")
    fi
    
    # 检查配置文件
    if [ ! -f "$CONFIG_DIR/config.ini" ]; then
        errors+=("配置文件缺失")
    fi
    
    # 检查 Python 脚本
    if ! python3 "$INSTALL_DIR/bin/command-ai-helper" --help &> /dev/null; then
        errors+=("Python 辅助脚本无法运行")
    fi
    
    if [ ${#errors[@]} -ne 0 ]; then
        print_error "安装验证失败:"
        for error in "${errors[@]}"; do
            print_error "  - $error"
        done
        exit 1
    fi
    
    print_success "安装验证通过"
}

# 显示安装后信息
show_post_install_info() {
    echo
    print_success "🎉 CommandAI 安装完成！"
    echo
    
    print_info "接下来的步骤:"
    print_info "1. 重新启动终端或运行: source ~/.zshrc"
    print_info "2. 编辑配置文件: $CONFIG_DIR/config.ini"
    print_info "3. 设置您的 API Key（如果尚未设置）"
    print_info "4. 运行 'ai help' 查看使用说明"
    
    echo
    print_info "配置文件位置:"
    print_info "  配置: $CONFIG_DIR/config.ini"
    print_info "  自定义 Prompt (INI): $CONFIG_DIR/custom-prompt-example.ini"
    print_info "  自定义 Prompt (Markdown): $CONFIG_DIR/custom-prompts.md"
    print_info "  黑名单: $CONFIG_DIR/blacklist.txt"
    print_info "  缓存: $CACHE_DIR"
    
    echo
    print_info "快速开始:"
    print_info "  ai 列出当前目录下的所有 .txt 文件"
    print_info "  ai fix  # 修复上一个失败的命令"
    print_info "  # 查找包含 error 的日志文件  # 自然语言转命令"
    
    if [ -d "$BACKUP_DIR" ]; then
        echo
        print_info "备份位置: $BACKUP_DIR"
    fi
    
    echo
    print_info "如需帮助，请查看 README.md 或运行 'ai help'"
}

# 卸载函数
uninstall() {
    print_info "开始卸载 CommandAI..."
    
    # 备份配置
    if [ -d "$CONFIG_DIR" ]; then
        read -p "是否备份配置文件? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            backup_dir="$HOME/.command-ai-uninstall-backup-$(date +%Y%m%d-%H%M%S)"
            mkdir -p "$backup_dir"
            cp -r "$CONFIG_DIR" "$backup_dir/"
            print_success "配置已备份到: $backup_dir"
        fi
    fi
    
    # 删除文件
    [ -d "$INSTALL_DIR" ] && rm -rf "$INSTALL_DIR"
    
    read -p "是否删除配置和缓存文件? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        [ -d "$CONFIG_DIR" ] && rm -rf "$CONFIG_DIR"
        [ -d "$CACHE_DIR" ] && rm -rf "$CACHE_DIR"
    fi
    
    # 清理 .zshrc
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        # 移除插件配置行
        grep -v "command-ai" "$zshrc" > "$zshrc.tmp" && mv "$zshrc.tmp" "$zshrc"
        print_success "已清理 .zshrc 配置"
    fi
    
    print_success "CommandAI 卸载完成"
}

# 主函数
main() {
    echo
    print_info "CommandAI 安装脚本"
    print_info "版本: 1.0.0"
    echo
    
    # 处理命令行参数
    case "${1:-install}" in
        install)
            check_dependencies
            check_python_packages
            check_zsh_setup
            backup_existing_config
            install_plugin_files
            install_config_files
            configure_zsh
            configure_api_key
            verify_installation
            show_post_install_info
            ;;
        uninstall)
            uninstall
            ;;
        *)
            echo "用法: $0 [install|uninstall]"
            echo "  install   - 安装 CommandAI (默认)"
            echo "  uninstall - 卸载 CommandAI"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
