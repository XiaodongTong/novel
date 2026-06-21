# TTS 语音列表

使用 edge-tts 将小说章节转为 MP3 音频。

## 用法

`bash
# 默认语音（XiaoxiaoNeural）
./tts.sh 1 10

# 指定语音
./tts.sh -v zh-CN-YunxiNeural 1 10
`

## 可用中文语音

| 语音 ID | 性别 | 风格 | 特点 |
|---------|------|------|------|
| zh-CN-XiaoxiaoNeural | 女 | 新闻、小说 | 温暖（默认） |
| zh-CN-XiaoyiNeural | 女 | 卡通、小说 | 活泼 |
| zh-CN-YunjianNeural | 男 | 体育、小说 | 激情 |
| zh-CN-YunxiNeural | 男 | 小说 | 活泼、阳光 |
| zh-CN-YunxiaNeural | 男 | 卡通、小说 | 可爱 |
| zh-CN-YunyangNeural | 男 | 新闻 | 专业、稳重 |
| zh-CN-liaoning-XiaobeiNeural | 女 | 方言（辽宁） | 幽默 |
| zh-CN-shaanxi-XiaoniNeural | 女 | 方言（陕西） | 明亮 |

## 推荐

- 修仙小说男主视角：zh-CN-YunxiNeural（阳光）或 zh-CN-YunjianNeural（激情）
- 女声旁白：zh-CN-XiaoxiaoNeural（温暖）

## 参考

- [微软 TTS 语音官方文档](https://learn.microsoft.com/en-us/azure/ai-services/speech-service/language-support?tabs=tts)
