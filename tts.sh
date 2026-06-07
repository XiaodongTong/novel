#!/bin/bash

if [ $# -ne 2 ]; then
    echo "用法: $0 <开始章节> <结束章节>"
    echo "示例: $0 1 10"
    exit 1
fi

START=$1
END=$2

if [ $START -gt $END ]; then
    echo "错误: 开始章节不能大于结束章节"
    exit 1
fi

mkdir -p ./output/mp3

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
    edge-tts --voice zh-CN-XiaoxiaoNeural -f "$FILE" --write-media "$OUTPUT" 2>&1

    if [ $? -eq 0 ]; then
        echo "完成: ${BASENAME}.mp3"
    else
        echo "失败: 第${i}章"
    fi
done

echo "全部完成!"
