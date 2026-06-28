#!/bin/bash

show_help() {
    cat <<'EOF'
用法: tts.sh [选项] <开始章节> <结束章节>

选项:
  -v VOICE       TTS 语音（默认 zh-CN-YunxiNeural）
  -d DIR         章节输入目录（首次使用需提供，之后可省略——会记忆到 ./.tts-config）
  -o DIR         音频输出目录（首次使用需提供，之后可省略——会记忆到 ./.tts-config）
  -p TEMPLATE    章节文件名前缀模板，printf 风格（默认 '第%d章 '，含一个 %d 槽位）
                 运行时把 %d 替换为章节号，再拼上 '*.txt' 作为 find 匹配模式
  -c FILE        配置文件路径（默认 ./.tts-config）
  --reset-config 删除配置文件，重新要求输入路径
  -h             显示此帮助

示例:
  # 首次：传入路径，生成成功后自动记忆
  tts.sh -d ./output/chapters -o ./output/mp3 1 10

  # 之后：路径从 .tts-config 自动读取，无需再传
  tts.sh 1 10

  # 改换项目时先重置
  tts.sh --reset-config
  tts.sh -d ./output/chapters -p '%03d-' -o ./output/mp3 1 10

  # 用自定义语音
  tts.sh -v zh-CN-XiaoxiaoNeural 1 10

可选语音:
  zh-CN-XiaoxiaoNeural          女，温暖    --新闻、小说
  zh-CN-XiaoyiNeural            女，活泼    --卡通、小说
  zh-CN-YunjianNeural           男，激情    --体育、小说
  zh-CN-YunxiNeural             男，阳光    --小说（默认）
  zh-CN-YunxiaNeural            男，可爱    --卡通、小说
  zh-CN-YunyangNeural           男，稳重    --新闻
  zh-CN-liaoning-XiaobeiNeural  女，幽默    --方言（辽宁）
  zh-CN-shaanxi-XiaoniNeural    女，明亮    --方言（陕西）

必须在项目根目录下执行（输入目录必须存在）。
配置文件首次成功生成 MP3 后写入，自动记忆输入/输出/前缀。
EOF
}

VOICE="zh-CN-YunxiNeural"
INPUT_DIR=""
OUTPUT_DIR=""
PREFIX_TEMPLATE='第%d章 '
CONFIG_FILE="./.tts-config"
RESET_CONFIG=0

# 长选项 --reset-config 自处理（getopts 不支持 --xxx）
NEW_ARGS=()
for arg in "$@"; do
    case $arg in
        --reset-config) RESET_CONFIG=1 ;;
        *) NEW_ARGS+=("$arg") ;;
    esac
done
set -- "${NEW_ARGS[@]}"

while getopts "v:d:o:p:c:h" opt; do
    case $opt in
        v) VOICE="$OPTARG" ;;
        d) INPUT_DIR="$OPTARG" ;;
        o) OUTPUT_DIR="$OPTARG" ;;
        p) PREFIX_TEMPLATE="$OPTARG" ;;
        c) CONFIG_FILE="$OPTARG" ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# --reset-config：删除配置后继续解析剩余参数
if [ "$RESET_CONFIG" = 1 ]; then
    rm -f "$CONFIG_FILE"
    echo "已重置配置文件: $CONFIG_FILE"
fi

# 加载配置：CLI 传入 > 配置文件；CONFIG 内若以 # 开头视为注释
# 字段值用双引号包起来（含空格的如 '第%d章 ' 不会被截尾），读出后 eval 拆引号
load_config() {
    local key="$1"
    [ -f "$CONFIG_FILE" ] || return 1
    # 取形如 key="value" 的第一行，把 key="..." 之外的部分 eval 一下
    local line
    line=$(grep -E "^[[:space:]]*${key}=\"" "$CONFIG_FILE" | head -1)
    [ -z "$line" ] && return 1
    # 去掉行首空白 + key= 前缀，剩下 "value" 用 eval 解引号
    local val="${line#*=}"
    val="${val#"${val%%[![:space:]]*}"}"   # 去掉前导空白
    eval "printf '%s' $val"
}

if [ -z "$INPUT_DIR" ]; then
    INPUT_DIR=$(load_config INPUT_DIR)
fi
if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR=$(load_config OUTPUT_DIR)
fi
if [ "$PREFIX_TEMPLATE" = '第%d章 ' ]; then
    # 仅在用户未通过 -p 显式传入时尝试从配置读取
    CFG_PREFIX=$(load_config PREFIX_TEMPLATE)
    [ -n "$CFG_PREFIX" ] && PREFIX_TEMPLATE="$CFG_PREFIX"
fi

if [ $# -ne 2 ]; then
    show_help
    exit 1
fi

START=$1
END=$2

if [ "$START" -gt "$END" ]; then
    echo "错误: 开始章节不能大于结束章节"
    exit 1
fi

if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "错误: 首次使用必须通过 -d 和 -o 指定输入/输出目录"
    echo "      生成成功后会自动记忆到 $CONFIG_FILE"
    exit 1
fi

if [ ! -d "$INPUT_DIR" ]; then
    echo "错误: 未找到输入目录 $INPUT_DIR，请在项目根目录下执行此脚本"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# 仅在 CLI 显式传过这些参数时，才在成功生成后写配置
# 判定：当前值与既有配置不同（或配置不存在），视为"用户本次输入过"
EXISTING_INPUT=$(load_config INPUT_DIR)
EXISTING_OUTPUT=$(load_config OUTPUT_DIR)
EXISTING_PREFIX=$(load_config PREFIX_TEMPLATE)
if [ "$INPUT_DIR" != "$EXISTING_INPUT" ] || [ "$OUTPUT_DIR" != "$EXISTING_OUTPUT" ] || [ "$PREFIX_TEMPLATE" != "$EXISTING_PREFIX" ]; then
    WRITE_CONFIG_NEEDED=1
fi

echo "语音:    $VOICE"
echo "输入:    $INPUT_DIR（前缀: $PREFIX_TEMPLATE）"
echo "输出:    $OUTPUT_DIR"
echo "范围:    第${START}章 ~ 第${END}章"
if [ "$WRITE_CONFIG_NEEDED" = 1 ] && [ ! -f "$CONFIG_FILE" ]; then
    echo "配置:    首次使用，成功后将写入 $CONFIG_FILE"
fi
echo ""

NEW_CONFIG_WROTE=0
for i in $(seq $START $END); do
    PATTERN=$(printf "${PREFIX_TEMPLATE}*.txt" "$i")
    FILE=$(find "$INPUT_DIR" -name "$PATTERN" -print -quit)

    if [ -z "$FILE" ]; then
        echo "跳过: 未找到第${i}章（匹配模式: $PATTERN）"
        continue
    fi

    BASENAME=$(basename "$FILE" .txt)
    OUTPUT="${OUTPUT_DIR}/${BASENAME}.mp3"

    if [ -f "$OUTPUT" ]; then
        echo "跳过: ${BASENAME}.mp3 已存在"
        continue
    fi

    # 长音频里给听众一个"现在是哪章"的锚点：开头拼一句章名
    TMP_INPUT=$(mktemp)
    {
        printf '%s。\n' "$BASENAME"
        cat "$FILE"
    } > "$TMP_INPUT"

    echo "处理: 第${i}章 -> ${BASENAME}.mp3"
    # edge-tts 服务端偶发断开（NoAudioReceived），加重试
    SUCCESS=0
    for attempt in 1 2 3 4 5; do
        edge-tts --voice "$VOICE" -f "$TMP_INPUT" --write-media "$OUTPUT" > /dev/null 2>&1
        if [ $? -eq 0 ] && [ -s "$OUTPUT" ]; then
            SUCCESS=1
            [ $attempt -gt 1 ] && echo "  重试第 $((attempt-1)) 次后成功"
            break
        fi
        rm -f "$OUTPUT"
        [ $attempt -lt 5 ] && sleep 2
    done

    rm -f "$TMP_INPUT"

    if [ $SUCCESS -eq 1 ]; then
        echo "完成: ${BASENAME}.mp3"
        # 第一次成功生成时写入配置
        if [ "$WRITE_CONFIG_NEEDED" = 1 ] && [ "$NEW_CONFIG_WROTE" = 0 ]; then
            TMP="${CONFIG_FILE}.tmp"
            {
                echo "# tts.sh 自动记忆的配置（不要手工编辑除非知道自己在做什么）"
                echo "INPUT_DIR=\"$INPUT_DIR\""
                echo "OUTPUT_DIR=\"$OUTPUT_DIR\""
                echo "PREFIX_TEMPLATE=\"$PREFIX_TEMPLATE\""
            } > "$TMP"
            mv "$TMP" "$CONFIG_FILE"
            NEW_CONFIG_WROTE=1
            echo "  已写入配置: $CONFIG_FILE"
        fi
    else
        echo "失败: 第${i}章（5 次重试均失败）"
    fi
done

echo "全部完成!"