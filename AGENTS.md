# CLAUDE.md —— 工程权威索引

> 本文件是工程的**唯一索引入口**。所有写作、审稿、维护工作，先读本文件。
> `AGENTS.md` 是本文件的软链，内容完全一致。
> **本文只做索引和路由，不做速查卡**。具体设定/规则/速查，按 §三 路径去对应文档读。

---

## 一、项目定位

玄幻修仙网文。**基调：热血打脸 + 权谋智力爽 + 实力跃升爽。**

**一句话内核**：现代医生穿越成"废灵根"，得古物**照墟玦**能看见他人看不见的真相（阵法/伪装/对己算计），但"看见 = 暴露"。看破不说破，从炼气一爬到筑基大圆满（前段七弧上限），靠**八维实力**（修为+功法+法宝+攻防逃幻阵）越阶战斗。

> 详细 pitch、三层钩子、势力格局 → `base/spine.md` 与 `base/world/`。

---

## 二、权威文档优先级（冲突时按此排序）

1. `base/world/` —— 世界观最高权威
2. `base/spine.md` —— 全书脊柱
3. `style/style-guide.md` —— 写作规范
4. `base/arcs/` —— 各弧章节级推进
5. `characters/` —— 人物设定
6. `progress/progress.md` + `progress/foreshadow.md` —— 进度与伏笔

> 任何冲突，以靠前文档为准。新机制必须先在 `base/world/` 登记。

---

## 三、文档地图（路由表）

### `base/world/` —— 世界观
- `00-世界观总纲.md` —— 三层世界 + 势力
- `01-古物与金手指.md` —— 照墟玦 + 三重视界 + 修炼辅助
- `02-被封印大能.md` —— 残魂 + 苏醒阶段
- `03-底层法则.md` —— 真相分层 + 未知存在
- `04-修炼成长.md` —— **实力线唯一权威**（八维 + 七弧曲线 + 越阶 + 突破四件套）

### `base/`
- `spine.md` —— 全书脊柱（pitch + 钩子 + 七弧 + 节点）
- `plan/` —— 后期主线方案稿

### `style/` —— 写作规范
- `style-guide.md` —— 总规范
- `beats-library.md` —— 节拍样板库
- `voice-baseline.md` —— 声音基线（17 条）
- `rules-baseline.md` —— 规则基线（含实力铁律 5 条）

### `base/arcs/README.md` —— 各弧推进

### `characters/` —— 人物
- `index.yaml` —— 索引

### `progress/` —— 动态台账
- `progress.md` —— 进度 + 三明线锚点 + 声音锚点
- `foreshadow.md` —— 五线伏笔台账

### `handbook/` —— 流程与硬约束
- `写作流程.md` —— **4-skill 章节流水线**（策划→作家→编辑→总编 + 退回逻辑 + 字数阈值表）
- `审稿准则.md` —— 主编三问 + 六特质 + 一票否决
- `格式铁律.md` —— 成品格式（txt、禁 md、字数、段落、破折号）

### `.agents/skills/` —— 章节生产 4 个 skill（由写作流程编排）
- `chapter-planner/` —— 策划：产出 chXX-beats.md（11 项章设计）
- `chapter-writer/` —— 作家：扩写第N章.txt 正文（2500-3000 字）
- `format-editor/` —— 编辑：字数/格式/段落/破折号审查（三态判定）
- `story-reviewer/` —— 总编：主编三问+六特质+合规审查（三态判定）

### `output/`
- `chapters/` —— 正文（txt，命名 `第N章 标题.txt`）
- `chapter-designs/` —— 章设计（`template.md` 模板 + `chXX-beats.md` 过程稿）

---

## 四、铁律入口

### 4.1 内容铁律（11 条）
1. 代价只能主角扛
2. 看破 ≠ 能赢
3. 医术绝不降维修仙界
4. 章末必有钩子
5. 反派不降智
6. 爽点节拍硬下限（5 章无小爽必须回升）
7. 程式化冻结（不复用已滥的公式）
8. 新机制必须先在 `base/world/` 登记
9. 章设计先于正文（12 项节拍蓝图，9 项强制项不满足不扩写；强制项 3「本章情节·场景级」是叙事骨架，必须先于机制项填实）
10. 实力线脊柱级·八维 → 详见 `base/world/04-修炼成长.md` 与 `style/rules-baseline.md §四`
11. **战斗胜利必有收获**（功法/法宝/丹药/灵石/妖核/情报等），当场清点；允许情绪弧例外（须写"本可拿+为何没拿"+后续补回）。详见 `style/rules-baseline.md §四` 第 9 条。

### 4.2 格式铁律
→ `handbook/格式铁律.md`（txt / 禁 markdown / 2500–3000 字 / 段落规范 / 破折号 `——`）

### 4.3 配角小档案三件套（强制）
每个核心配角必须含「**小档案（戏剧引擎）**」：**欲望** / **算计** / **盲点**。

---

## 五、工作流程

- **写新章节**：按 `handbook/写作流程.md` 执行 **4-skill 流水线**——主对话顺序触发 chapter-planner → chapter-writer → format-editor → story-reviewer，按各 skill 输出的 verdict 路由（含退回）。每个 skill 自带「读取协议」精确控制读取集，**不要一次性把所有 base/style 全读进上下文**。
- **审稿**：格式审查由 format-editor（机械），故事审查由 story-reviewer（主编三问+合规）。两者独立，顺序固定：先编辑后总编。
- **修改设定**：先改 `base/world/` → 同步 `base/spine.md` / `base/arcs/` / `characters/` → 更新 `progress/foreshadow.md`。

---

## 六、工程约定

- **禁止使用 MCP 工具**
- 正文输出到 `output/chapters/`，命名 `第N章 标题.txt`
