#!/usr/bin/env python3
"""
番茄小说批量上传脚本（草稿箱）
依赖：pip install DrissionPage

使用流程：
  1. 关闭所有 Chrome 窗口
  2. 终端执行：
     /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
       --remote-debugging-port=9222 --user-data-dir=/tmp/chrome-debug
  3. 在该 Chrome 里登录 fanqienovel.com，打开草稿箱
  4. 跑 dry-run 模式探测页面元素（MODE="probe"）
  5. 把 SELECTORS 填好
  6. 先 TEST_ONLY=78 试传 1 章
  7. 改 MODE="upload" 批量上传
"""

import re
import subprocess
import sys
import time
from pathlib import Path
from DrissionPage import ChromiumPage, ChromiumOptions

# ============== 路径与范围 ==============
CHAPTER_DIR = Path("/Users/russell/workingspace/novel/output/chapters")
START = 78
END = 150
TEST_ONLY = None  # 设成 78 表示只传第 78 章试水；正式批量传时设成 None

# ============== 浏览器 ==============
DEBUG_HOST = "127.0.0.1"
DEBUG_PORT = 9222
DRAFT_URL = (
    "https://fanqienovel.com/main/writer/chapter-manage/"
    "7645832626699242558&%E8%A2%AB%E9%80%90%E5%87%BA%E5%AE%97%E9%97%A8"
    "%E5%90%8E%EF%BC%8C%E6%88%91%E6%88%90%E4%BA%86%E4%B8%87%E6%B0%91%E4%B9%8B"
    "%E4%B8%BB?type=2"
)
PUBLISH_URL = (
    "https://fanqienovel.com/main/writer/7645832626699242558/"
    "publish/?enter_from=newdraft"
)

# ============== 上传行为 ==============
MODE = "upload"                # "probe" = dry-run 探测；"upload" = 实际传
TEST_ONLY = None               # 跑全量；试水时设成具体章节号（如 78）
TITLE_MODE = "short"           # 标题栏只填章节名（"济世堂"），章节号填到独立输入框
INTERVAL_SEC = 5               # 每章之间的等待秒数（防风控）
EDITOR_INDEX = 0               # 第几个 ProseMirror（0=正文，其他是 AI 工具）
STRIP_HR = False              # 是否删除正文里的 "---" 分隔线

# ============== 元素选择器（已验证）==============
SELECTORS = {
    "chapter_num_input": 'xpath://input[@type="text" and not(@placeholder)]',
    "title_input": "@placeholder=请输入标题",
    "content_editor": "tag:div@class=ProseMirror",  # 取第 EDITOR_INDEX 个
    "save_draft_btn": "text=存草稿",
}

# =========================================================

CHAPTER_RE = re.compile(r"^第(\d+)章\s+(.+?)\.md$")


def list_chapters(start: int, end: int):
    """从磁盘列出 start..end 范围的章节文件，按编号升序。"""
    pairs = []
    for p in CHAPTER_DIR.iterdir():
        m = CHAPTER_RE.match(p.name)
        if not m:
            continue
        n = int(m.group(1))
        if start <= n <= end:
            pairs.append((n, p))
    pairs.sort(key=lambda x: x[0])
    return pairs


def make_title(filepath: Path, n: int, mode: str) -> str:
    """full=整段文件名；short=去掉「第N章 」前缀。"""
    stem = filepath.stem
    if mode == "short":
        return stem.split(" ", 1)[1] if " " in stem else stem
    return stem


def clean_content(text: str) -> str:
    text = text.strip()
    # 默认删除场景分隔的 --- ，如要保留改 STRIP_HR=False 无效（永远删）
    text = re.sub(r"\n-{3,}\n", "\n\n", text)
    if STRIP_HR:
        text = re.sub(r"\n-{3,}\n", "\n\n", text)
    return text


def connect_browser() -> ChromiumPage:
    """接管以调试模式启动的 Chrome（复用登录态）。"""
    co = ChromiumOptions()
    co.set_address(f"{DEBUG_HOST}:{DEBUG_PORT}")
    return ChromiumPage(addr_or_opts=co)


def probe(page: ChromiumPage):
    """dry-run：打开草稿箱，打印页面信息供识别 selector。"""
    page.get(DRAFT_URL)
    time.sleep(2.5)
    print("=" * 60)
    print("URL :", page.url)
    print("TITLE:", page.title)
    print("=" * 60)
    body = page.ele("tag:body")
    print("\n--- 可见文本（前 1500 字）---")
    print(body.text[:1500] if body else "<no body>")
    print("\n--- body 前 4000 字符 HTML ---")
    print(body.html[:4000] if body else "<no body>")
    print("\n--- 所有可点击的按钮 / 链接 ---")
    for tag in ("button", "a"):
        for el in page.eles(f"tag:{tag}"):
            txt = (el.text or "").strip()
            if txt:
                print(f"  [{tag}] {txt!r}  attrs={dict(el.attrs)}")


def fill_editor(page: ChromiumPage, content: str):
    """填正文：JS 触发 paste 事件，ProseMirror 按其 pasteRules 处理（双换行分段）。"""
    editors = page.eles(SELECTORS["content_editor"])
    if len(editors) <= EDITOR_INDEX:
        raise RuntimeError(f"ProseMirror 数量={len(editors)} < 期望索引 {EDITOR_INDEX}")
    editor = editors[EDITOR_INDEX]
    editor.click()
    time.sleep(0.3)
    # 1. 清空占位符/残留
    editor.run_js("""
      this.focus();
      const sel = window.getSelection();
      const range = document.createRange();
      range.selectNodeContents(this);
      sel.removeAllRanges();
      sel.addRange(range);
      document.execCommand('delete');
    """)
    time.sleep(0.3)
    # 2. 程序化触发 paste 事件，clipboardData 带纯文本
    editor.run_js(
        """
        const text = arguments[0];
        this.focus();
        const dt = new DataTransfer();
        dt.setData('text/plain', text);
        const evt = new ClipboardEvent('paste', { bubbles: true, cancelable: true });
        Object.defineProperty(evt, 'clipboardData', { value: dt });
        this.dispatchEvent(evt);
        """,
        content,
    )
    time.sleep(0.8)


def upload_one(page: ChromiumPage, n: int, fp: Path):
    title = make_title(fp, n, TITLE_MODE)
    content = clean_content(fp.read_text(encoding="utf-8"))
    print(f"  · 第 {n} 章  标题={title!r}  章节号={n}  字数={len(content)}")

    # 1. 直接导航到新建草稿页（每次都会生成新 chapter ID）
    page.get(PUBLISH_URL)
    time.sleep(2)

    # 2. 填章节号
    num_el = page.ele(SELECTORS["chapter_num_input"])
    num_el.clear()
    num_el.input(str(n))
    time.sleep(0.3)

    # 3. 填标题（只填章节名）
    title_el = page.ele(SELECTORS["title_input"])
    title_el.clear()
    title_el.input(title)
    time.sleep(0.3)

    # 4. 填正文（剪贴板粘贴）
    fill_editor(page, content)

    # 5. 保存草稿
    page.ele(SELECTORS["save_draft_btn"]).click()
    time.sleep(INTERVAL_SEC)


def main():
    chapters = list_chapters(START, END)
    if not chapters:
        print(f"在 {CHAPTER_DIR} 找不到第 {START}-{END} 章的文件")
        sys.exit(1)
    if TEST_ONLY is not None:
        chapters = [c for c in chapters if c[0] == TEST_ONLY]
    print(f"将处理 {len(chapters)} 章：{chapters[0][0]} ~ {chapters[-1][0]}")

    page = connect_browser()

    if MODE == "probe":
        probe(page)
        print("\n请把识别到的 selector 填到脚本顶部的 SELECTORS 里，然后改 MODE='upload'。")
        return

    if MODE == "upload":
        if not all(SELECTORS.values()):
            print("⚠️  SELECTORS 没填全：", {k: v for k, v in SELECTORS.items() if not v})
            sys.exit(1)
        # 先打开草稿箱页登录态预热（同时让用户看到当前状态）
        page.get(DRAFT_URL)
        time.sleep(2)
        for i, (n, fp) in enumerate(chapters, 1):
            print(f"\n[{i}/{len(chapters)}]", end="")
            try:
                upload_one(page, n, fp)
            except Exception as e:
                print(f"  ❌ 第 {n} 章失败：{e}")
                sys.exit(1)
        print("\n✅ 全部完成，去草稿箱检查一下。")
    else:
        print(f"未知 MODE={MODE!r}")


if __name__ == "__main__":
    main()
