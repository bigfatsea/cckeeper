# Claude Code 数据解析核心逻辑分析

## 概述

本文档详细分析了 `ccusage` 工具如何解析 Claude Code 的使用数据，以及 `claude-keeper` 工具在判断活跃区块（active blocks）时存在的问题。

## 1. 数据存储结构

Claude Code 将使用数据存储在本地文件系统中，采用 JSONL（JSON Lines）格式：

```
~/.config/claude/projects/    # 新版默认路径
~/.claude/projects/          # 旧版默认路径
    └── {project_name}/      # 项目名称
        └── {session_id}/    # 会话 ID
            └── *.jsonl      # 使用数据文件
```

### 1.1 多路径支持

`ccusage` 支持同时从多个 Claude 数据目录读取数据：

```typescript
// data-loader.ts:67-120
export function getClaudePaths(): string[] {
  const paths = [];
  
  // 1. 首先检查环境变量（支持逗号分隔的多路径）
  const envPaths = process.env.CLAUDE_CONFIG_DIR?.trim();
  if (envPaths) {
    // 支持多路径：CLAUDE_CONFIG_DIR="/path1,/path2"
    const envPathList = envPaths.split(',').map(p => p.trim());
    // ...
  }
  
  // 2. 添加默认路径
  const defaultPaths = [
    DEFAULT_CLAUDE_CONFIG_PATH,      // ~/.config/claude
    path.join(USER_HOME_DIR, '.claude')  // ~/.claude
  ];
  
  // 3. 返回所有有效路径（自动去重）
  return paths;
}
```

## 2. JSONL 数据格式

每行 JSONL 包含一次 API 调用的使用数据：

```typescript
// data-loader.ts:144-163
export const usageDataSchema = z.object({
  timestamp: isoTimestampSchema,        // ISO 格式时间戳
  version: versionSchema.optional(),    // Claude Code 版本
  message: z.object({
    usage: z.object({
      input_tokens: z.number(),         // 输入令牌数
      output_tokens: z.number(),        // 输出令牌数
      cache_creation_input_tokens: z.number().optional(),  // 缓存创建令牌
      cache_read_input_tokens: z.number().optional(),      // 缓存读取令牌
    }),
    model: modelNameSchema.optional(),  // 使用的模型名称
    id: messageIdSchema.optional(),     // 消息 ID（用于去重）
    content: z.array(...).optional(),   // 消息内容
  }),
  costUSD: z.number().optional(),       // 预计算的成本（美元）
  requestId: requestIdSchema.optional(), // 请求 ID（用于去重）
  isApiErrorMessage: z.boolean().optional(), // API 错误标记
});
```

## 3. 会话区块（Session Blocks）计算逻辑

### 3.1 核心概念

- **会话区块**：Claude 的计费单位，默认为 5 小时
- **活跃区块**：当前正在使用的区块
- **间隙区块**：两个活动之间超过 5 小时的空白期

### 3.2 区块识别算法

```typescript
// _session-blocks.ts:90-154
export function identifySessionBlocks(
  entries: LoadedUsageEntry[],
  sessionDurationHours = 5
): SessionBlock[] {
  const sessionDurationMs = sessionDurationHours * 60 * 60 * 1000;
  const blocks: SessionBlock[] = [];
  
  // 1. 按时间戳排序
  const sortedEntries = [...entries].sort((a, b) => 
    a.timestamp.getTime() - b.timestamp.getTime()
  );
  
  for (const entry of sortedEntries) {
    if (currentBlockStart == null) {
      // 首个条目：创建新区块（时间向下取整到小时）
      currentBlockStart = floorToHour(entry.timestamp);
      currentBlockEntries = [entry];
    } else {
      const timeSinceBlockStart = entry.timestamp - currentBlockStart;
      const timeSinceLastEntry = entry.timestamp - lastEntry.timestamp;
      
      if (timeSinceBlockStart > sessionDurationMs || 
          timeSinceLastEntry > sessionDurationMs) {
        // 超过 5 小时：关闭当前区块，创建新区块
        blocks.push(createBlock(...));
        
        // 如果间隔超过 5 小时，创建间隙区块
        if (timeSinceLastEntry > sessionDurationMs) {
          blocks.push(createGapBlock(...));
        }
        
        // 开始新区块
        currentBlockStart = floorToHour(entry.timestamp);
      }
    }
  }
}
```

### 3.3 活跃区块判断

`ccusage` 的活跃区块判断逻辑：

```typescript
// _session-blocks.ts:168
const isActive = now.getTime() - actualEndTime.getTime() < sessionDurationMs && now < endTime;
```

判断条件：
1. 距离最后一次活动时间 < 5 小时
2. 当前时间 < 区块结束时间（开始时间 + 5 小时）

## 4. 数据去重机制

为避免重复计算，使用消息 ID 和请求 ID 组合进行去重：

```typescript
// data-loader.ts:514-524
export function createUniqueHash(data: UsageData): string | null {
  const messageId = data.message.id;
  const requestId = data.requestId;
  
  if (messageId == null || requestId == null) {
    return null;
  }
  
  // 创建唯一标识符
  return `${messageId}:${requestId}`;
}
```

## 5. 成本计算模式

`ccusage` 支持三种成本计算模式：

```typescript
// data-loader.ts:606-638
export async function calculateCostForEntry(
  data: UsageData,
  mode: CostMode,
  fetcher: PricingFetcher
): Promise<number> {
  if (mode === 'display') {
    // 仅显示预计算的成本
    return data.costUSD ?? 0;
  }
  
  if (mode === 'calculate') {
    // 始终根据令牌数计算
    return fetcher.calculateCostFromTokens(...);
  }
  
  if (mode === 'auto') {
    // 自动模式：优先使用预计算成本，否则计算
    if (data.costUSD != null) {
      return data.costUSD;
    }
    return fetcher.calculateCostFromTokens(...);
  }
}
```

## 6. claude-keeper 的问题分析

### 6.1 当前实现

`claude-keeper` 的活跃判断逻辑过于简单：

```javascript
// claude-keeper:111-164
getLatestActivity() {
  // 1. 查找所有 JSONL 文件
  const allJsonlFiles = this.findJsonlFiles(projectsPath);
  
  // 2. 遍历所有文件，找到最新的时间戳
  let latestTime = null;
  for (const file of allJsonlFiles) {
    const lines = content.trim().split('\n');
    for (const line of lines) {
      const data = JSON.parse(line);
      if (data.timestamp) {
        const time = new Date(data.timestamp);
        if (!latestTime || time > latestTime) {
          latestTime = time;
        }
      }
    }
  }
  return latestTime;
}

// claude-keeper:233
if (timeSinceActivity < this.config.sessionDuration) {
  // 仅检查最后活动时间是否在 5 小时内
  this.log('info', '✅ Block is active');
}
```

### 6.2 存在的问题

1. **没有区块概念**：只查看最后一次活动时间，不理解 5 小时区块的概念
2. **缺少区块边界判断**：不检查当前时间是否超过区块结束时间
3. **忽略间隙区块**：无法识别活动间隙
4. **过于简化**：可能误判区块状态

### 6.3 正确的实现方式

`claude-keeper` 应该采用类似 `ccusage` 的逻辑：

```javascript
// 建议的改进
function checkActiveBlock() {
  const entries = loadAllEntries();
  const blocks = identifySessionBlocks(entries);
  
  // 找到最后一个区块
  const lastBlock = blocks[blocks.length - 1];
  
  // 判断是否活跃
  const now = new Date();
  const timeSinceLastActivity = now - lastBlock.actualEndTime;
  const isActive = timeSinceLastActivity < SESSION_DURATION && 
                   now < lastBlock.endTime;
  
  return { isActive, lastBlock };
}
```

## 7. 数据聚合功能

`ccusage` 提供多种数据聚合方式：

### 7.1 按日聚合
```typescript
// data-loader.ts:716-855
export async function loadDailyUsageData(options?: LoadOptions): Promise<DailyUsage[]> {
  // 1. 收集所有文件
  // 2. 按时间戳排序
  // 3. 解析并去重
  // 4. 按日期分组
  // 5. 计算每日总计
}
```

### 7.2 按会话聚合
```typescript
// data-loader.ts:863-1037
export async function loadSessionData(options?: LoadOptions): Promise<SessionUsage[]> {
  // 根据文件路径结构提取会话信息
  // 格式：projects/{project}/{session}/{file}.jsonl
}
```

### 7.3 按月聚合
```typescript
// data-loader.ts:1045-1120
export async function loadMonthlyUsageData(options?: LoadOptions): Promise<MonthlyUsage[]> {
  // 基于日数据进行月度聚合
}
```

### 7.4 按区块聚合
```typescript
// data-loader.ts:1128-1244
export async function loadSessionBlockData(options?: LoadOptions): Promise<SessionBlock[]> {
  // 加载所有数据并识别 5 小时区块
}
```

## 8. 关键优化

1. **并行处理**：同时从多个 Claude 路径加载数据
2. **内存效率**：使用流式处理 JSONL 文件
3. **去重优化**：使用 Set 结构进行 O(1) 查找
4. **时间戳排序**：确保按时间顺序处理数据
5. **错误容错**：跳过无效的 JSON 行，继续处理

## 9. 总结

`ccusage` 实现了一个完整的 Claude Code 数据解析系统，正确处理了：
- 多路径数据源
- 5 小时计费区块
- 活跃区块判断
- 数据去重
- 多维度聚合

而 `claude-keeper` 的实现过于简化，建议：
1. 采用区块概念而非简单的时间差判断
2. 正确识别区块边界
3. 处理间隙区块
4. 参考 `ccusage` 的 `identifySessionBlocks` 实现

这样才能准确判断当前区块是否真正活跃，避免不必要的激活操作。