#!/bin/bash

# Claude Block Keeper 自动化配置脚本
# 
# 该脚本将自动配置 Claude Block Keeper 的 crontab 任务
# 包括：
# - 验证脚本路径
# - 创建日志目录
# - 安装 crontab 任务
# - 验证配置

set -e  # 遇到错误时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 打印标题
echo -e "${BLUE}=================================${NC}"
echo -e "${BLUE} Claude Block Keeper 配置脚本${NC}"
echo -e "${BLUE}=================================${NC}"
echo

# 获取当前脚本所在目录作为默认路径
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SCRIPT_PATH="${CURRENT_DIR}/claude-block-keeper.js"

# 获取用户输入的脚本路径
while true; do
    echo -e "${BLUE}请输入 claude-block-keeper.js 的完整路径：${NC}"
    echo -e "${YELLOW}默认路径：${DEFAULT_SCRIPT_PATH}${NC}"
    echo -e "${YELLOW}直接按回车使用默认路径，或输入自定义路径：${NC}"
    read -r SCRIPT_PATH
    
    # 如果用户直接按回车，使用默认路径
    if [[ -z "$SCRIPT_PATH" ]]; then
        SCRIPT_PATH="$DEFAULT_SCRIPT_PATH"
    fi
    
    # 去除路径两端的空白字符和引号
    SCRIPT_PATH=$(echo "$SCRIPT_PATH" | sed 's/^["'\''[:space:]]*//' | sed 's/["'\''[:space:]]*$//')
    
    # 验证文件是否存在
    if [[ -f "$SCRIPT_PATH" ]]; then
        print_success "找到脚本文件: $SCRIPT_PATH"
        break
    else
        print_error "文件不存在: $SCRIPT_PATH"
        echo "请检查路径是否正确，然后重新输入。"
        echo
    fi
done

# 获取脚本所在目录
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
LOG_DIR="${SCRIPT_DIR}/logs"
START_SCRIPT_PATH="${SCRIPT_DIR}/start-block-keeper.sh"

print_info "脚本目录: $SCRIPT_DIR"
print_info "日志目录: $LOG_DIR"
print_info "启动脚本: $START_SCRIPT_PATH"

# 验证脚本是否可执行
if [[ ! -x "$SCRIPT_PATH" ]]; then
    print_warning "脚本不可执行，正在添加执行权限..."
    chmod +x "$SCRIPT_PATH"
    print_success "已添加执行权限"
fi

# 验证启动脚本是否存在和可执行
if [[ ! -f "$START_SCRIPT_PATH" ]]; then
    print_error "启动脚本不存在: $START_SCRIPT_PATH"
    echo "请确保 start-block-keeper.sh 存在于脚本目录中"
    exit 1
fi

if [[ ! -x "$START_SCRIPT_PATH" ]]; then
    print_warning "启动脚本不可执行，正在添加执行权限..."
    chmod +x "$START_SCRIPT_PATH"
    print_success "已为启动脚本添加执行权限"
fi

# 创建日志目录
if [[ ! -d "$LOG_DIR" ]]; then
    print_info "创建日志目录: $LOG_DIR"
    mkdir -p "$LOG_DIR"
    print_success "日志目录创建成功"
else
    print_info "日志目录已存在"
fi

# 测试启动脚本运行
print_info "测试启动脚本运行..."
if "$START_SCRIPT_PATH" > /dev/null 2>&1; then
    print_success "启动脚本测试运行成功"
else
    print_error "启动脚本测试运行失败"
    echo "请确保："
    echo "1. Node.js 已安装且在 PATH 中"
    echo "2. claude-block-keeper.js 语法正确"
    echo "3. start-block-keeper.sh 具有执行权限"
    echo "4. 所需权限已授予"
    exit 1
fi

# 检查 Node.js 路径
NODE_PATH=$(which node)
if [[ -z "$NODE_PATH" ]]; then
    print_error "未找到 Node.js，请确保 Node.js 已安装"
    exit 1
fi
print_info "Node.js 路径: $NODE_PATH"

# 设置运行频率为固定值
CRON_SCHEDULE="30 0,4-23 * * *"
DESCRIPTION="每天的半点执行（跳过凌晨1:30、2:30和3:30）"

print_info "设置的运行频率: $DESCRIPTION ($CRON_SCHEDULE)"

# 检查是否已存在 Claude Block Keeper 任务
if crontab -l 2>/dev/null | grep -q "claude-block-keeper"; then
    print_warning "检测到现有的 Claude Block Keeper 任务"
    echo "现有任务："
    crontab -l | grep "claude-block-keeper"
    echo
    read -p "是否覆盖现有任务？(y/n): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "保留现有任务，取消安装"
        exit 0
    fi
    print_info "将覆盖现有任务"
fi

# 创建新的 crontab 文件
TEMP_CRONTAB="/tmp/my_crontab_$$"

print_info "创建 crontab 文件..."
cat > "$TEMP_CRONTAB" << EOF
# Claude Block Keeper - $DESCRIPTION运行
$CRON_SCHEDULE "$START_SCRIPT_PATH" > "$LOG_DIR/block-keeper.log" 2>&1
EOF

# 显示将要安装的 crontab
echo
print_info "将要安装的 crontab 任务："
echo -e "${YELLOW}----------------------------------------${NC}"
cat "$TEMP_CRONTAB"
echo -e "${YELLOW}----------------------------------------${NC}"
echo

# 安装 crontab
print_info "正在安装 crontab 任务..."
if crontab "$TEMP_CRONTAB"; then
    print_success "Crontab 任务安装成功"
else
    print_error "Crontab 任务安装失败"
    rm "$TEMP_CRONTAB"
    exit 1
fi

# 清理临时文件
rm "$TEMP_CRONTAB"

# 验证安装
echo
print_info "验证安装结果："
echo -e "${YELLOW}当前 crontab 任务：${NC}"
crontab -l | grep -A 1 -B 1 "claude-block-keeper" || print_error "未找到安装的任务"

# 测试日志写入
LOG_FILE="$LOG_DIR/block-keeper.log"
print_info "测试日志写入权限..."
if echo "[$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")] 配置脚本测试日志" >> "$LOG_FILE"; then
    print_success "日志写入测试成功"
else
    print_error "日志写入测试失败，请检查目录权限"
fi

# 提供使用说明
echo
print_success "配置完成！"
echo
echo -e "${BLUE}使用说明：${NC}"
echo "• 任务将按照设定的时间自动运行"
echo "• 启动脚本位置: $START_SCRIPT_PATH"
echo "• 日志文件位置: $LOG_FILE"
echo "• 手动运行: \"$START_SCRIPT_PATH\""
echo "• 查看日志: tail -f \"$LOG_FILE\""
echo "• 查看 crontab: crontab -l"
echo "• 删除任务: crontab -e (删除 Claude Block Keeper 相关行)"
echo
echo -e "${YELLOW}macOS 用户注意事项：${NC}"
echo "• 如果任务无法运行，可能需要在 '系统偏好设置 > 安全性与隐私 > 隐私 > 完全磁盘访问权限' 中添加 cron"
echo "• 首次运行后建议检查日志确保正常工作"
echo
echo -e "${GREEN}设置完成！Claude Block Keeper 将自动维护您的 Claude Code 活跃状态。${NC}"