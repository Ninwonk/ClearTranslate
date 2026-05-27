# ClearTranslate Technical Doc

## 1. 技术目标

ClearTranslate 使用 Flutter 构建跨平台客户端，目标是在单一代码库下支持 Windows、macOS、Android 和 iOS。

技术设计原则：

- 核心翻译逻辑与 UI 解耦
- 翻译 Provider 可替换
- API Key 与普通业务数据分离存储
- 本地优先，不依赖自有服务端
- 长文本翻译可取消、可重试、可显示进度

## 2. 推荐技术栈

| 模块 | 技术 |
| --- | --- |
| 框架 | Flutter |
| 语言 | Dart |
| 状态管理 | Riverpod |
| 网络请求 | Dio |
| 本地数据库 | Drift / SQLite |
| 敏感信息存储 | flutter_secure_storage |
| 语音输入 | speech_to_text，后续阶段接入 |
| 桌面打包 | Flutter desktop build |
| 移动端打包 | Flutter Android / iOS build |

说明：

- iOS 和 macOS 构建需要 macOS 环境。
- Windows 构建需要 Windows 环境。
- Android 可在 Windows、macOS、Linux 上构建，但需要 Android SDK。

## 3. 分层架构

```text
Flutter App
├── Presentation Layer
│   ├── Home Page
│   ├── History Page
│   └── Settings Page
│
├── Application Layer
│   ├── TranslateController
│   ├── DictionaryController
│   ├── HistoryController
│   └── SettingsController
│
├── Domain Layer
│   ├── TranslationRequest
│   ├── TranslationResult
│   ├── DictionaryEntry
│   ├── TranslationMode
│   └── TranslationProvider
│
├── Infrastructure Layer
│   ├── OpenAICompatibleClient
│   ├── LocalDatabase
│   ├── SecureStorage
│   └── SpeechService
│
└── Shared
    ├── Theme
    ├── Constants
    ├── Error Handling
    └── Utils
```

## 4. 建议目录结构

```text
lib/
├── main.dart
├── app.dart
├── presentation/
│   ├── home/
│   ├── history/
│   └── settings/
├── application/
│   ├── translate/
│   ├── dictionary/
│   ├── history/
│   └── settings/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── providers/
├── infrastructure/
│   ├── api/
│   ├── database/
│   ├── secure_storage/
│   └── speech/
└── shared/
    ├── theme/
    ├── constants/
    ├── errors/
    └── utils/
```

## 5. Provider 抽象

第一版只实现 OpenAI-compatible Provider，但接口应为后续 DeepSeek、Qwen、Gemini、OpenRouter 或自定义服务预留空间。

```dart
abstract interface class TranslationProvider {
  Future<TranslationResult> translate(TranslationRequest request);

  Future<DictionaryEntry> lookup(DictionaryRequest request);

  Stream<TranslationProgress> translateLongText(LongTextTranslationRequest request);

  Future<void> cancel(String requestId);
}
```

Provider 类型规划：

```text
TranslationProvider
├── OpenAICompatibleProvider
├── DeepSeekProvider
├── QwenProvider
├── GeminiProvider
└── CustomProvider
```

v0.1 只需要：

```text
OpenAICompatibleProvider
```

## 6. 翻译请求流程

普通文本翻译：

```text
用户输入
-> 语言识别
-> 构建 TranslationRequest
-> 读取 Provider 配置和 API Key
-> 调用 OpenAI-compatible API
-> 输出 TranslationResult
-> 根据设置写入历史
```

长文本翻译：

```text
用户输入长文本
-> 按段落切分 chunk
-> 逐段请求翻译
-> 记录每段进度
-> 失败段落可重试
-> 合并输出
-> 保存历史
```

取消翻译：

```text
用户点击取消或按 Esc
-> Controller 发出 cancel
-> Dio CancelToken 取消当前请求
-> 停止后续 chunk
-> UI 显示已取消状态
```

## 7. 数据模型

### history_records

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | text | 主键 |
| source_text | text | 原文 |
| translated_text | text | 译文或词典结果 |
| source_language | text | 源语言 |
| target_language | text | 目标语言 |
| mode | text | translate / dictionary |
| provider | text | Provider 名称 |
| model | text | 模型名称 |
| created_at | datetime | 创建时间 |
| updated_at | datetime | 更新时间 |
| is_favorite | bool | 是否收藏 |

### app_settings

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | int | 固定设置记录 ID |
| default_source_language | text | 默认源语言 |
| default_target_language | text | 默认目标语言 |
| default_provider | text | 默认 Provider |
| default_model | text | 默认模型 |
| translation_style | text | natural / accurate / formal / concise |
| save_history_enabled | bool | 是否保存历史 |
| theme_mode | text | system / light / dark |
| chunk_size | int | 长文本分段长度 |

### provider_configs

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| id | text | 主键 |
| provider_name | text | Provider 名称 |
| base_url | text | API Base URL |
| api_key_storage_key | text | secure storage 中的 key |
| model_name | text | 模型名称 |
| is_enabled | bool | 是否启用 |
| created_at | datetime | 创建时间 |

API Key 不直接存入普通数据库，只在数据库中保存 secure storage key name。

## 8. Prompt 模板

### 普通翻译

```text
你是一个专业中英翻译引擎。
请将用户输入翻译为{target_language}。

要求：
1. 保留原文段落结构。
2. 保留 Markdown、列表、编号、代码块。
3. 不要添加解释。
4. 翻译自然、准确、符合目标语言表达习惯。
5. 如果原文有明显错别字，可在不改变意思的前提下自然修正。

用户输入：
{input}
```

### 长文本翻译

```text
你正在翻译一篇长文的第 {current_chunk} / {total_chunks} 段。
请将以下内容翻译为{target_language}。

要求：
1. 保持术语一致。
2. 保留段落、标题、列表和 Markdown 格式。
3. 不要总结，不要省略。
4. 只输出译文。
5. 翻译风格：{style}

上下文术语参考：
{glossary}

待翻译内容：
{chunk}
```

### 词典模式

```text
你是一个专业中英双语词典。
用户输入了一个英文单词或短语，请按固定结构输出词典解释。

输出结构：
1. 单词 / 短语
2. 发音提示
3. 词性
4. 核心释义
5. 常见用法
6. 固定搭配
7. 例句，中英双语
8. 近义词
9. 易混词区别
10. 使用建议

要求：
- 中文解释要清楚。
- 英文例句要自然。
- 不要编造罕见用法。
- 如果这是短语，请解释短语整体含义。

用户输入：
{input}
```

## 9. 错误处理

错误类型：

- API Key 缺失
- API Key 无效
- 网络不可用
- 请求超时
- 请求被取消
- Provider 返回格式异常
- 模型拒绝或返回空内容
- 数据库存储失败

UI 展示原则：

- 错误信息要能指导用户下一步操作
- 不暴露完整 API Key
- 不显示无意义的堆栈信息
- 长文本翻译中要标明失败 chunk

## 10. 安全和隐私

本地数据策略：

- API Key 使用 flutter_secure_storage
- 历史记录使用 Drift / SQLite
- 默认不上传历史记录到自有服务器
- 设置项和 Provider 配置仅本地保存

用户提示：

- 如果使用第三方模型，输入文本会发送给对应 API 服务商
- 历史记录可关闭
- 后续应支持清空历史

## 11. 测试策略

单元测试：

- 语言识别
- 文本分段
- Prompt 构建
- Provider 请求参数
- 错误映射

集成测试：

- 设置保存和读取
- API Key 存取
- 历史记录写入和查询
- 翻译请求成功和失败路径

界面测试：

- 桌面双栏布局
- 移动上下布局
- 深色模式
- 错误状态
- 加载和取消状态

