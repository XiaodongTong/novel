# 上传章节到番茄小说（草稿箱）

将 `output/chapters/*.md` 批量上传到番茄小说作家后台草稿箱。

**核心脚本**：与本 skill 同目录的 `upload_fanqie.py`（所有配置集中在脚本顶部）

## 触发条件

用户说"上传番茄小说"、"传草稿箱"、"上传章节"、"upload fanqie"，或 `/upload-fanqie`。

## 流程

### 1. 环境检查
- Chrome 是否在 9222 调试端口运行：
  ```bash
  lsof -nP -iTCP:9222 -sTCP:LISTEN
  ```
- 未运行则提示用户启动：
  ```bash
  pkill -f "Google Chrome" 2>/dev/null; sleep 2
  mkdir -p /tmp/chrome-debug-fanqie
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --remote-debugging-port=9222 \
    --user-data-dir=/tmp/chrome-debug-fanqie \
    > /tmp/chrome-debug.log 2>&1 &
  ```
- 用户需在该 Chrome 里登录番茄作家后台，打开草稿箱 URL（`?type=2`）

### 2. 试传 1 章
- 修改脚本：`TEST_ONLY = 78`（或其他具体编号）、`INTERVAL_SEC = 5`、`MODE = "upload"`、`TITLE_MODE = "short"`
- 执行：
  ```bash
  cd workspace && python3 upload_fanqie.py
  ```
- **让用户去草稿箱验证四项**：
  1. 章节号是否填入独立输入框
  2. 标题是否只有章节名（不带"第N章"前缀）
  3. 正文是否完整、段落是否正常、`---` 是否删除
  4. 没有"自动化测试"等脏数据残留

### 3. 批量上传
- 试传 OK 后改 `TEST_ONLY = None`，后台执行：
  ```bash
  python3 .claude/commands/upload_fanqie.py
  ```
- 73 章约需 10 分钟，建议 `run_in_background=true`

## 关键技术沉淀（踩过的坑）

1. **Chrome 调试端口必须用非默认 user-data-dir**
   Chrome 149 拒绝用 `~/Library/Application Support/Google/Chrome` 默认目录开调试端口，必须用独立目录（如 `/tmp/chrome-debug-fanqie`）。

2. **章节号 ≠ 标题，是两个独立 input**
   - 章节号：`xpath://input[@type="text" and not(@placeholder)]`（class 含 `serial-input byte-input byte-input-size-default`）
   - 标题：`@placeholder=请输入标题`（**只填章节名**如"济世堂"，不要带"第N章"）

3. **正文是 ProseMirror 编辑器，三种填法对比**
   - ❌ `editor.input(content)`：每个 `\n` 都分段，段间多空行
   - ❌ `pbcopy` + `page.actions.key_down('v')`（Ctrl+V）：DrissionPage 的 key_down 不真正触发 paste 事件
   - ✅ **JS dispatchEvent paste 事件**（这是唯一可行的方案）：
     ```js
     const dt = new DataTransfer();
     dt.setData('text/plain', text);
     const evt = new ClipboardEvent('paste', { bubbles: true, cancelable: true });
     Object.defineProperty(evt, 'clipboardData', { value: dt });
     editor.dispatchEvent(evt);
     ```
     ProseMirror 的 pasteRules 按双换行分段，跟 Markdown 一致。

4. **正文里的 `---` 分隔线自动删除**
   在 `clean_content()` 里硬编码 `re.sub(r"\n-{3,}\n", "\n\n", text)`。

5. **不要往真实草稿箱写"自动化测试"等字样**
   会触发风控。dry-run 探测时往编辑器里塞占位文本，要确保没点"存草稿"。

## 配置项

| 配置 | 默认 | 说明 |
|---|---|---|
| `CHAPTER_DIR` | `output/chapters` | 章节目录 |
| `START` / `END` | 78 / 150 | 章节范围 |
| `TEST_ONLY` | None | 设具体编号试传 1 章；批量传设 None |
| `INTERVAL_SEC` | 5 | 每章间隔秒数（防风控） |
| `TITLE_MODE` | "short" | 标题只填章节名 |
| `DEBUG_PORT` | 9222 | Chrome 调试端口 |
| `DRAFT_URL` | (已配置) | 草稿箱 URL（`?type=2`） |

## 失败处理

- 脚本中失败立即 `sys.exit(1)`，等用户判断再决定是否重跑
- 重跑时改 `START` 为失败章节号，`END` 保持不变
- 若触发风控（章节频率过快），把 `INTERVAL_SEC` 增大到 8~10 秒

## 收尾（清理调试 Chrome）

调试 Chrome 跑在**独立 user-data-dir**（`/tmp/chrome-debug-fanqie`），与默认 Chrome 完全隔离：
- **磁盘数据**：调试 Chrome 只动 `/tmp/chrome-debug-fanqie/`，**默认 Chrome 数据（`~/Library/Application Support/Google/Chrome/`）永不被修改**——`pkill` 杀进程不会丢 cookies / 书签 / 历史
- **进程隔离**：可与默认 Chrome 同时跑（不同 user-data-dir）

启动默认 Chrome（登录态自动恢复）：
```bash
open -a "Google Chrome"
```

完全清理调试 Chrome：
```bash
# 杀掉调试 Chrome 进程
lsof -nP -iTCP:9222 -sTCP:LISTEN | grep LISTEN | awk '{print $2}' | xargs kill
# 删独立配置目录
rm -rf /tmp/chrome-debug-fanqie
```

## 后续可优化（未实现）

- [ ] **断点续传**：解析草稿箱列表，跳过已上传章节
- [ ] **失败自动重试**：单章失败重试 N 次后跳过
- [ ] **章节号自动识别**：已实现（脚本按文件名"第N章 *.md"提取编号）