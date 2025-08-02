#!/usr/bin/env node

/**
 * Claude Block Keeper
 * 
 * 自动维持 Claude Code 活跃块的脚本
 * 通过定时检查并在必要时激活新块，确保不错过任何 5 小时计费周期
 * 
 * 用法：
 *   ./claude-block-keeper.js                 # 正常模式：仅在没有活跃块时激活新块
 *   ./claude-block-keeper.js --force-activate # 强制模式：无论是否有活跃块都执行命令
 * 
 * 输出日志到 stdout，可通过重定向保存到文件：
 * ./claude-block-keeper.js >> block-keeper.log 2>&1
 */

import fs from 'fs';
import path from 'path';
import os from 'os';
import { execSync } from 'child_process';

// 配置
const SESSION_DURATION_MS = 5 * 60 * 60 * 1000; // 5 小时

// 获取 Claude 数据目录
function getClaudePaths() {
  const paths = [];
  
  // 检查环境变量
  const envPaths = process.env.CLAUDE_CONFIG_DIR;
  if (envPaths) {
    envPaths.split(',').forEach(p => {
      const trimmed = p.trim();
      if (trimmed && fs.existsSync(path.join(trimmed, 'projects'))) {
        paths.push(trimmed);
      }
    });
  }
  
  // 默认路径
  const defaultPaths = [
    path.join(os.homedir(), '.config', 'claude'),
    path.join(os.homedir(), '.claude')
  ];
  
  defaultPaths.forEach(p => {
    if (fs.existsSync(path.join(p, 'projects')) && !paths.includes(p)) {
      paths.push(p);
    }
  });
  
  return paths;
}

// 递归查找所有 JSONL 文件
function findJsonlFiles(dir) {
  const files = [];
  
  function walk(currentPath) {
    try {
      const items = fs.readdirSync(currentPath);
      for (const item of items) {
        const fullPath = path.join(currentPath, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory()) {
          walk(fullPath);
        } else if (item.endsWith('.jsonl')) {
          files.push(fullPath);
        }
      }
    } catch (err) {
      // 忽略权限错误等
    }
  }
  
  walk(dir);
  return files;
}

// 解析 JSONL 文件获取最新活动时间
function getLatestActivity(files) {
  let latestTime = null;
  let latestEntry = null;
  
  for (const file of files) {
    try {
      const content = fs.readFileSync(file, 'utf8');
      const lines = content.trim().split('\n').filter(line => line);
      
      for (const line of lines) {
        try {
          const data = JSON.parse(line);
          if (data.timestamp) {
            const time = new Date(data.timestamp);
            if (!latestTime || time > latestTime) {
              latestTime = time;
              latestEntry = data;
            }
          }
        } catch (err) {
          // 忽略解析错误的行
        }
      }
    } catch (err) {
      // 忽略文件读取错误
    }
  }
  
  return { latestTime, latestEntry };
}

// 格式化时间为新加坡时区 (UTC+8)
function formatSingaporeTime(date) {
  return date.toLocaleString('sv-SE', { 
    timeZone: 'Asia/Singapore',
    year: 'numeric',
    month: '2-digit', 
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  }).replace(' ', 'T');
}

// 写入日志
function log(message) {
  const now = new Date();
  const timestamp = formatSingaporeTime(now);
  const logEntry = `[${timestamp}] ${message}`;
  console.log(logEntry);
}

// 激活新块
function activateNewBlock() {
  try {
    // 执行简单的 Claude Code 命令
    // 使用 echo 命令发送一个简单的数学计算，最小化 token 使用
    const command = 'claude --dangerously-skip-permissions "1+1"';
    
    log('🔄 激活新块...');
    
    const output = execSync(command, { 
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
    
    log(`✅ 新块已激活`);
    return true;
  } catch (err) {
    log(`❌ 激活失败: ${err.message}`);
    return false;
  }
}

// 解析命令行参数
function parseArgs() {
  const args = process.argv.slice(2);
  return {
    forceActivate: args.includes('--force-activate')
  };
}

// 主函数
function main() {
  const { forceActivate } = parseArgs();
  
  if (forceActivate) {
    log('🚀 强制激活模式');
  }
  
  log('🔍 检查 Claude 块状态...');
  
  // 获取 Claude 数据目录
  const claudePaths = getClaudePaths();
  if (claudePaths.length === 0) {
    log('❌ 未找到 Claude 数据目录');
    process.exit(1);
  }
  
  // 查找所有 JSONL 文件
  const allJsonlFiles = [];
  for (const claudePath of claudePaths) {
    const projectsPath = path.join(claudePath, 'projects');
    if (fs.existsSync(projectsPath)) {
      const files = findJsonlFiles(projectsPath);
      allJsonlFiles.push(...files);
    }
  }
  
  log(`📁 ${claudePaths.length} 目录, ${allJsonlFiles.length} 文件`);
  
  if (allJsonlFiles.length === 0) {
    log('⚠️ 无使用数据，激活新块');
    activateNewBlock();
    return;
  }
  
  // 获取最新活动时间
  const { latestTime, latestEntry } = getLatestActivity(allJsonlFiles);
  
  if (!latestTime) {
    log('⚠️ 无有效活动时间，激活新块');
    activateNewBlock();
    return;
  }
  
  // 检查是否有活跃块
  const now = new Date();
  const timeSinceLastActivity = now - latestTime;
  const hoursElapsed = timeSinceLastActivity / (1000 * 60 * 60);
  
  // 转换为 hh:mm 格式
  const totalMinutes = Math.floor(timeSinceLastActivity / (1000 * 60));
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  const timeFormatted = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`;
  
  log(`⏰ 最后活动: ${formatSingaporeTime(latestTime)} (${timeFormatted} 前)`);
  
  if (forceActivate) {
    // 强制激活模式下，无论块是否活跃都执行命令
    log('🔧 强制激活模式，执行 Claude 命令');
    activateNewBlock();
  } else if (timeSinceLastActivity < SESSION_DURATION_MS) {
    // 正常模式下，如果块仍然活跃，仅显示状态
    log(`✅ 活跃块: ${latestEntry?.message?.model || '未知'} ($${latestEntry?.costUSD || 0})`);
  } else {
    // 正常模式下，块已过期时激活新块
    log('❌ 块已过期，激活新块');
    activateNewBlock();
  }
  
  log('✨ 检查完成\n');
}

// 错误处理
process.on('uncaughtException', (err) => {
  log(`💥 异常: ${err.message}`);
  process.exit(1);
});

process.on('unhandledRejection', (err) => {
  log(`💥 Promise拒绝: ${err}`);
  process.exit(1);
});

// 运行主函数
main();