#!/bin/bash

show_help() {
    cat <<'EOF'
用法: tts.sh [-v 语音] <开始章节> <结束章节>

示例:
  tts.sh 1 10
  tts.sh -v zh-CN-YunxiNeural 1 10

可选语音:
  zh-CN-XiaoxiaoNeural          女，温暖    --新闻、小说（默认）
  zh-CN-XiaoyiNeural            女，活泼    --卡通、小说
  zh-CN-YunjianNeural           男，激情    --体育、小说
  zh-CN-YunxiNeural             男，阳光    --小说
  zh-CN-YunxiaNeural            男，可爱    --卡通、小说
  zh-CN-YunyangNeural           男，稳重    --新闻
  zh-CN-liaoning-XiaobeiNeural  女，幽默    --方言（辽宁）
  zh-CN-shaanxi-XiaoniNeural    女，明亮    --方言（陕西）
EOF
}

VOICE="zh-CN-XiaoxiaoNeural"

while getopts "v:h" opt; do
    case $opt in
        v) VOICE="$OPTARG" ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done
shift $((OPTIND-1))

if [ $# -ne 2 ]; then
    show_help
    exit 1
fi

START=$1
END=$2

if [ $START -gt $END ]; then
    echo "错误: 开始章节不能大于结束章节"
    exit 1
fi

mkdir -p ./output/mp3

echo "语音: $VOICE"
echo "范围: 第${START}章 ~ 第${END}章"
echo ""

for i in $(seq $START $END); do
    FILE=$(find ./output/chapters -name "第${i}章 *.md" -print -quit)

    if [ -z "$FILE" ]; then
        echo "跳过: 未找到第${i}章"
        continue
    fi

    BASENAME=$(basename "$FILE" .md)
    OUTPUT="./output/mp3/${BASENAME}.mp3"

    if [ -f "$OUTPUT" ]; then
        echo "跳过: ${BASENAME}.mp3 已存在"
        continue
    fi

    echo "处理: 第${i}章 -> ${BASENAME}.mp3"
    edge-tts --voice "$VOICE" -f "$FILE" --write-media "$OUTPUT" 2>&1

    if [ $? -eq 0 ]; then
        echo "完成: ${BASENAME}.mp3"
    else
        echo "失败: 第${i}章"
    fi
done

echo "全部完成!"
