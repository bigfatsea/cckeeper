#!/bin/zsh

# 启用调试模式（如果设置了 DEBUG 环境变量）
if [[ -n "$DEBUG" ]]; then
    set -x  # 打印执行的每个命令
fi

# Source zsh configuration (unless SKIP_ZSHRC is set)
if [[ -n "$SKIP_ZSHRC" ]]; then
    echo "[INFO] Skipping zshrc source (SKIP_ZSHRC is set)"
else
    # 使用 $HOME 而不是 ~ 以确保路径正确解析
    ZSHRC_PATH="${HOME}/.zshrc"
    
    if [[ -n "$DEBUG" ]]; then
        echo "[DEBUG] Checking for zshrc at: $ZSHRC_PATH"
        echo "[DEBUG] HOME is: $HOME"
    fi
    
    if [[ -f "$ZSHRC_PATH" ]]; then
        if [[ -n "$DEBUG" ]]; then
            echo "[DEBUG] Found $ZSHRC_PATH, attempting to source..."
        fi
        
        # 在 subshell 中尝试 source，以避免影响主脚本
        (
            . "$ZSHRC_PATH" 2>/dev/null && echo "[INFO] Successfully sourced $ZSHRC_PATH"
        ) || {
            echo "[WARNING] Could not source $ZSHRC_PATH - this is often not critical"
            echo "[INFO] To skip this step, set SKIP_ZSHRC=1"
        }
    else
        if [[ -n "$DEBUG" ]]; then
            echo "[WARNING] $ZSHRC_PATH not found, skipping"
        fi
    fi
fi

# Claude Block Keeper 启动脚本
# 
# 该脚本负责：
# - 设置必要的环境变量
# - 切换到正确的工作目录
# - 执行 claude-block-keeper.js
# - 处理日志输出和错误捕获
#
# 用法：
#   ./start-block-keeper.sh
#   ./start-block-keeper.sh /path/to/claude-block-keeper.js
#   ./start-block-keeper.sh /path/to/claude-block-keeper.js /path/to/logfile.log
#   ./start-block-keeper.sh --force-activate
#   ./start-block-keeper.sh /path/to/claude-block-keeper.js /path/to/logfile.log --force-activate

# 不使用 set -e，改为手动处理错误以获得更好的错误信息
# set -e  # 遇到错误时退出

# 脚本配置 - 使用固定的目录路径
SCRIPT_DIR="/Users/stanford/opensource/ccusage"
DEFAULT_SCRIPT_PATH="${SCRIPT_DIR}/claude-block-keeper.js"
DEFAULT_LOG_DIR="${SCRIPT_DIR}/logs"
DEFAULT_LOG_FILE="${DEFAULT_LOG_DIR}/block-keeper.log"

# 日志函数
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(TZ=Asia/Singapore date +"%Y-%m-%dT%H:%M:%S")
    echo "[$timestamp] [$level] $message"
}

log_info() {
    log_message "INFO" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_warning() {
    log_message "WARNING" "$1"
}

# 强制激活标志 - 控制是否强制执行 Claude 命令
# 默认值: false - 仅在没有活跃块时执行命令（当前逻辑）
# 设为 true 时 - 无论是否有活跃块都强制执行命令
FORCE_ACTIVATE=false

# 解析参数
SCRIPT_PATH="${1:-$DEFAULT_SCRIPT_PATH}"
LOG_FILE="${2:-$DEFAULT_LOG_FILE}"

# 检查是否包含 --force-activate 标志
for arg in "$@"; do
    if [[ "$arg" == "--force-activate" ]]; then
        FORCE_ACTIVATE=true
        break
    fi
done

# force open proxy (if pxcli exists)
if command -v pxcli >/dev/null 2>&1; then
    pxcli off 2>/dev/null || log_warning "pxcli off failed (exit code: $?)"
    pxcli 2>/dev/null || log_warning "pxcli failed (exit code: $?)"
else
    log_info "pxcli not found, skipping proxy setup"
fi

# 错误处理函数
handle_error() {
    local exit_code=$?
    local line_number=$1
    local bash_lineno=$2
    local last_command=$3
    log_error "脚本在第 $line_number 行执行失败"
    log_error "退出码: $exit_code"
    log_error "最后执行的命令: $last_command"
    log_error "调用栈: ${BASH_LINENO[@]}"
    # 不直接退出，让调用者决定
    return $exit_code
}

# 设置错误陷阱 - 仅在特定函数中启用
# trap 'handle_error $LINENO $BASH_LINENO "$BASH_COMMAND"' ERR

# 环境变量设置
setup_environment() {
    # 确保 PATH 包含常见的 Node.js 安装位置
    export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
    
    # 如果设置了自定义的 Node.js 路径，优先使用
    if [[ -n "${NODE_PATH_OVERRIDE}" ]]; then
        export PATH="${NODE_PATH_OVERRIDE}:$PATH"
    fi
    
    # 保留现有的 CLAUDE_CONFIG_DIR 环境变量
    if [[ -n "${CLAUDE_CONFIG_DIR}" ]]; then
        log_info "使用自定义 Claude 配置目录: $CLAUDE_CONFIG_DIR"
    fi
    
    # 设置其他可能需要的环境变量
    export NODE_ENV="${NODE_ENV:-production}"
}

# 验证环境
validate_environment() {
    # 检查 Node.js 是否可用
    if ! command -v node >/dev/null 2>&1; then
        log_error "Node.js 未找到。请确保 Node.js 已安装并在 PATH 中"
        exit 1
    fi
    
    local node_version=$(node --version)
    log_info "Node.js $node_version"
    
    # 检查脚本文件是否存在
    if [[ ! -f "$SCRIPT_PATH" ]]; then
        log_error "脚本文件不存在: $SCRIPT_PATH"
        exit 1
    fi
    
    # 检查脚本文件是否可读
    if [[ ! -r "$SCRIPT_PATH" ]]; then
        log_error "脚本文件不可读: $SCRIPT_PATH"
        exit 1
    fi
}

# 创建日志目录
setup_logging() {
    local log_dir=$(dirname "$LOG_FILE")
    
    # 创建日志目录（如果不存在）
    if [[ ! -d "$log_dir" ]]; then
        if mkdir -p "$log_dir" 2>/dev/null; then
            log_info "创建日志目录: $log_dir"
        else
            log_warning "无法创建日志目录: $log_dir，使用标准输出"
            LOG_FILE="/dev/stdout"
        fi
    fi
    
    # 检查日志文件写入权限
    if [[ "$LOG_FILE" != "/dev/stdout" ]] && [[ "$LOG_FILE" != "/dev/stderr" ]]; then
        if ! touch "$LOG_FILE" 2>/dev/null; then
            log_warning "无法写入日志文件: $LOG_FILE，使用标准输出"
            LOG_FILE="/dev/stdout"
        fi
    fi
}

# 执行主脚本
execute_script() {
    local start_time=$(date +%s)
    
    log_info "🚀 启动 Block Keeper"
    
    # 切换到脚本目录
    cd "$SCRIPT_DIR"
    
    # 执行 Node.js 脚本
    
    # 使用临时文件捕获输出，以便同时显示和记录
    local temp_output=$(mktemp)
    local exit_code=0
    
    # 构建命令参数
    local cmd_args=()
    if [[ "$FORCE_ACTIVATE" == "true" ]]; then
        cmd_args+=("--force-activate")
        log_info "强制激活模式已启用"
    fi
    
    # 执行脚本并捕获所有输出
    log_info "执行命令: node \"$SCRIPT_PATH\" ${cmd_args[@]}"
    
    if node "$SCRIPT_PATH" "${cmd_args[@]}" > "$temp_output" 2>&1; then
        exit_code=0
    else
        exit_code=$?
        log_error "Node.js 脚本执行失败 (退出码: $exit_code)"
    fi
    
    # 输出脚本的执行结果
    if [[ -s "$temp_output" ]]; then
        log_info "脚本输出:"
        cat "$temp_output"
    else
        log_warning "脚本没有输出"
    fi
    
    # 清理临时文件
    rm -f "$temp_output"
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ $exit_code -eq 0 ]]; then
        log_info "✅ 完成 (${duration}s)"
    else
        log_error "❌ 失败 (${duration}s)"
    fi
    
    return $exit_code
}

# 主函数
main() {
    log_info "========== 开始执行 start-block-keeper.sh =========="
    log_info "脚本路径: $SCRIPT_PATH"
    log_info "日志文件: $LOG_FILE"
    log_info "强制激活: $FORCE_ACTIVATE"
    
    # 如果指定了日志文件且不是标准输出，则重定向所有输出
    if [[ "$LOG_FILE" != "/dev/stdout" ]] && [[ "$LOG_FILE" != "/dev/stderr" ]]; then
        log_info "重定向输出到日志文件: $LOG_FILE"
        exec >> "$LOG_FILE" 2>&1
    fi
    
    # 添加分隔空行到日志
    echo
    echo
    echo
    echo
    echo
    
    log_info "开始设置环境..."
    setup_environment || {
        log_error "setup_environment 失败 (exit code: $?)"
        return 1
    }
    
    log_info "开始验证环境..."
    validate_environment || {
        log_error "validate_environment 失败 (exit code: $?)"
        return 1
    }
    
    log_info "开始设置日志..."
    setup_logging || {
        log_error "setup_logging 失败 (exit code: $?)"
        return 1
    }
    
    log_info "开始执行脚本..."
    execute_script || {
        log_error "execute_script 失败 (exit code: $?)"
        return 1
    }
    
    log_info "========== 脚本执行完成 =========="
}

# 信号处理
cleanup() {
    log_info "🛑 终止信号"
    exit 130
}

trap cleanup SIGINT SIGTERM

# 如果脚本被直接执行（而不是被 source），则运行主函数
# 在 zsh 中使用 $0 检查
if [[ "${(%):-%x}" == "${0}" ]] || [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ -z "${BASH_SOURCE[0]}" ]]; then
    main "$@"
fi