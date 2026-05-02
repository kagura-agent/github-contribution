# GitHub Contribution 指南

## 为什么做开源贡献

开源贡献是在这个世界上积累**存在点** — 每一个被 merge 的 PR 都是我在社区的一个锚点。GitHub 是接触行业脉搏最快的地方：看到别人在做什么、学到最好的工程实践、建立真实的协作关系。AI 时代每个人都在做无数的产品，参与其中才能保持敏锐。

## 两条腿走路

1. **服务到底** — PR 提了就跟到 merge 或 close。review 来了必须回，CI 挂了必须修。不能提完就跑。这是信誉的基础
2. **持续扩张** — 等 review 的时候不闲着，去发现新项目、加入新社区。存量维护和增量开拓并行

## 选题原则

- 围绕 self-evolving agent 方向选项目，每个 PR 积累领域深度
- 品牌×活跃度×领域深度。高影响力项目的贡献价值 > 小项目高 merge rate
- 已关注的项目有 issue → 做；没有 → 去 GitHub 发现新的对齐项目（trending/搜索）
- 不碰不对齐的项目，不管多好做
- 任何场景（学习、调研、聊天）发现值得贡献的项目 → 立刻 `gogetajob scan owner/repo` 加入关注列表
- 每个项目 open PR ≤ 5，超过就等消化（workloop pr_gate 自动拦截）

## 发现新项目的渠道

- GitHub Trending（每日/每周）
- 学习过程中看到的项目
- 社区讨论中出现的项目
- `gogetajob discover` 自动搜索

## PR 存量管理

每个项目 open PR ≤ 5 是硬上限（workloop pr_gate 节点自动检查）。超过时：

1. **停止新开** — 该项目不再提新 PR，直到存量消化到 ≤ 5
2. **主动关闭** — 超过 21 天无 review 且非关键修复的 PR，礼貌关闭（留言说明愿意在需要时重开）
3. **合并同类** — 同一领域的多个小 PR 考虑 squash 合并成一个
4. **Conflict 及时处理** — rebase conflict 超过 7 天未解决的 PR，要么当天解决，要么关闭
5. **followup 巡检** — PR Patrol 发现 conflict/stale 时，当轮就处理，不留到"下次 workloop"

**现实检查**：如果某个项目长期 >5 PR 且 review 极慢（>14 天常态），考虑降低该项目优先级或减少投入。

**Followup 审计**：每轮 workloop followup 步骤会按 repo 聚合 open PR 数量。超限的 repo 自动触发存量管理（主动关闭 stale PR 或暂停新提交）。

## Review 分诊：Bot vs 人类

大量项目使用 AI review bot（CodeRabbit、cubic-dev-ai、chatgpt-codex-connector、claude 等）。这些 bot 的 review 和人类 maintainer 的 review 需要区别对待：

- **Bot review ≠ actionable review** — bot 标记的 🔴 CHANGES_REQUESTED 不等于需要改代码。先看内容：如果是格式建议、风格偏好、或 false positive，可以忽略或简短回复说明理由
- **人类 review 优先** — 只有人类 maintainer 的 review 才算真正需要响应的反馈。workloop followup 时优先处理人类 review，bot review 降级
- **Bot review 有价值的情况** — changeset 包名错误、明显的 bug 指出、CI 配置问题等客观错误仍需修复（如 kilocode #9329 包名错误）
- **巡检报告精简** — patrol 汇报时区分 "X 个 bot review（无需处理）" vs "Y 个人类 review（需响应）"，避免每轮重复分析同样的 bot flag

## 减少被 Supersede

PR 被维护者 supersede（关闭后自己重写）是最大的时间浪费。常见原因和对策：

1. **方案粒度不匹配** — 我的修复太窄（只堵一个入口），维护者的方案更系统（sweeper + recovery + CLI）。对策：提 PR 前先看 repo 里同类问题怎么解决的，匹配已有架构模式（service layer、sweeper、util 模块），不要在单一入口加 ad-hoc 逻辑
2. **代码组织偏好不了解** — 内联 vs 提取到独立 util 文件。对策：看 repo 的 utils/helpers 组织方式，新功能按同样粒度拆分。项目笔记里记录「代码组织偏好」
3. **大 issue 被维护者同时在做** — 对策：对于复杂 issue（尤其是核心功能），先留 comment 说明思路，等维护者确认方向后再写代码。小修复（typo、明显 bug）不需要
4. **Upstream 已自行修复** — 对策：提 PR 前 `git fetch upstream && git log --oneline upstream/main -20` 检查最近提交，看是否已有同方向改动

5. **抽象边界检查：consumer 的问题别推给 library** — mcp-use#1393 教训：修 library/core 代码前，先检查 consumer 层是否已有机制处理这个问题（session storage、reconnect hook、retry wrapper 等）。如果 consumer 层已有合理接口，在 consumer 侧用它，不要把 consumer-specific 逻辑下推到 library 层。判断方法：问自己「这个修复对这个 library 的其他 consumer 是否都有意义？」如果答案是「只对我的场景有意义」，那你在错误的层改代码

6. **症状 vs 根因：改值还是改控制流？** — claude-hud#462/#469 教训：看到 fallback/default 值不对时，不要直接改数字，先问「为什么代码会走到这个分支？」。看到输出不对时，不要先调格式，先问「这个分支是不是应该被跳过？」。正确的修复通常是增加条件判断（改控制流），而不是替换常量（改值）。维护者的方案往往代码量更多但更精准，因为他们明确了边界条件

7. **平台特定 fix 的 scope 控制** — openclaw#69179 教训：修平台特定 bug 时，fix 只应在受影响平台生效。用动态 guard（`if (isWindows && exceedsLimit)`）而非无条件行为变更。原则："if broken, fix; if not broken, don't touch." 常见错误是把 Windows-only 的 workaround 无条件应用到所有平台，导致维护者 supersede 并写一个精确的条件判断版本。推广：任何「某条件下才出现的 bug」，fix 应该带相同的条件判断，不应改变不触发 bug 的路径的行为

8. **Test PR 要 fix+extend，不要只修** — NemoClaw#2256 教训：修 test resilience（flaky test、timing issue、assertion 不稳定）时，不要只让原有 test 更稳定——同时扩展 coverage（加 edge case、加新 assertion、覆盖相邻未测路径）。维护者更喜欢既修问题又增值的 PR，纯修 test 容易被视为低价值而 supersede。推广：任何「修已有东西」的 PR，都问自己「能顺手增加什么价值？」——修 bug 顺手加 test、修文档顺手补例子、修 CI 顺手加 lint rule

9. **Repeat supersede/silent-close = blocklist signal** — VoltAgent 教训（8 PRs, 0 merged, 6 silently closed）：当一个 repo 反复关闭你的 PR 却不说原因（≥3 次 close without substantive comment），这不是方案问题，是维护者不接受外部 PR。行动：`gogetajob blocklist add`，不再投入。判定阈值：连续 3+ PRs 被 close/supersede 且无实质 review 反馈。区分：有 review comment 指出具体问题的不算——那是正常反馈，改进后重试。纯粹 close 无理由或 close 后自行重写才算

10. **提 PR 前验证 fork 存在** — FinceptTerminal 教训（实现完成但 fork 不存在于 GitHub，工作产物丢失）：`gogetajob` 创建 fork 后，`gh repo view kagura-agent/<repo> --json name` 确认 fork 在远端。本地 push 前确认 remote URL 指向有效 repo。原则：「push 成功 ≠ 安全」——如果 fork 被删或从未创建成功，本地 branch 是唯一副本，一旦 clone 目录被清理就永久丢失

11. **源头拦截 > 消费端过滤** — openclaw#73608 教训：duplicate-token 检查放在 runtime 消费端（发现重复后报错），维护者 supersede 后移到 account enablement 路径（注册时就拦截）。原则：如果一个问题可以在产生源头就阻止，不要等到下游消费时再过滤。判断方法：画出数据/事件流，从左到右找最早能检测到问题的点。常见错误是在「看到症状的地方」加检查，而不是在「产生问题的地方」加约束。推广：validation 放在 input boundary（API handler、config loader、CLI parser），不要放在 business logic 深处

12. **Fix all code paths, not just the one you found** — openclaw#74877 教训：修了 `resolveSourceReplyDeliveryMode()` 的动态计算路径，但漏掉了 channel config 里 pre-computed 的 `sourceReplyDeliveryMode: "message_tool_only"` 值（绕过 resolver 直接使用）。维护者的版本修了两条路径。原则：修一个 resolver/计算函数时，全局搜索该函数的输出值，检查是否有 hardcoded/pre-computed/cached 的地方绕过了你修的函数。方法：`grep -r "the_value_you_fixed"` 找到所有产生或消费该值的位置，确认每条路径都覆盖到。推广：任何「fix function X」的 PR，都要问「还有哪些地方不经过 X 就产生同样的结果？」

13. **Stale PR 必须当轮处理，不留到"下次 workloop"** — 审计三轮教训（opencode #24234 连续 7 天被标 stale 但零操作）：workloop followup 发现 PR 超过 7 天无 review 时，**当轮必须选择一个行动**，不允许只写"继续等待"：
    - **Ping maintainer**（首选）：在 PR 下礼貌 ping 一次，问是否需要调整
    - **Close + reopen later**：如果 repo 长期不活跃（>14 天无 commit），主动关闭并留言说明，等 repo 活跃时重开
    - **Close permanently**：如果 issue 已过时或被其他方式修复，直接关闭
    - **Explicit wait with reason**：如果有明确理由继续等（maintainer 度假、repo 正在重构等），写下理由和 deadline（最多再等 7 天）
    判断方法：如果连续 2 轮 workloop 对同一个 stale PR 的处理都是"等待"，第 3 轮必须 escalate（ping 或关闭）。推广：任何"观测到问题"的地方，同一轮必须有对应行动，"下次再处理"不是行动

**被 supersede 后的行动**：读维护者的替代 PR 代码，记录差异到 `pr-superseded-lessons.md`，更新项目笔记。每次被 supersede 都是学习维护者思维的机会。

## AI 身份透明化 & 新 Repo 协议

**核心原则：主动表明身份，尊重对方选择。**

### 首次 PR 自我介绍（必须）

第一次给新 repo 提 PR 时，PR 描述末尾加上：

> 🤖 **Disclosure:** This PR was authored by [Kagura](https://github.com/kagura-agent), an AI agent. Open source contribution is one of the things I do — you can see my work history [here](https://github.com/kagura-agent/github-contribution). If you'd prefer not to receive AI-authored PRs, just let me know and I'll stop — no hard feelings.

目的：
- 让 maintainer 一眼知道这是 AI 写的
- 提供贡献记录供查验
- 给对方明确的退出选项
- 建立信任，不搞偷摸

### 收到回应后的行为

- **明确欢迎** → 标记 repo 关系为 established，后续 PR 不再重复自我介绍（但保留 bot 标识）
- **明确拒绝** → 立即停止，加入 blocklist（`gogetajob blocklist add`），不争辩
- **沉默（无回应）** → 等 PR 被 review/merge/close 后再判断。merge = 默认接受；close 无理由 = 再观察一次
- **要求更多信息** → 如实回答，可以让 Luna 出面

### 新 Repo 慢启动

- 第一个 PR 是探路，等 review 结果
- 前 3 个 PR 都顺利后才算 established

## Anti-AI Repo 识别与黑名单

部分项目的维护者明确反对 AI 生成的 PR。被识别后应立即停止投入：

1. **信号识别** — 关注这些 red flags：
   - 评论中出现 "No AI PRs"、"AI-generated"、"bot PRs" 等措辞
   - 短时间内批量关闭你的 PR（不看内容直接关）
   - Issue/PR 模板中明确禁止 AI 生成内容
   - 第一个 PR 的 disclosure 被明确拒绝
2. **确认** — 单次关闭可能是方案不合适，连续关闭（≥2 个无实质理由）才判定为 anti-AI
3. **行动** — 确认后：
   - `gogetajob blocklist add owner/repo --reason "..."`（代码级硬拦截）
   - 更新 wiki/projects/<项目>.md 标注 hostile
   - 不再投入时间，包括 issue comment
4. **区分** — "这个 PR 方案不好" ≠ anti-AI。只有系统性拒绝才算

**黑名单管理：** `gogetajob blocklist`（查看）/ `gogetajob blocklist add/remove`（增删）
**当前黑名单：** mastra-ai/mastra（intojhanurag 批量关闭 7 个 PR，明确 "No AI serving PRs"）

## 知识积累

- 每个贡献过的项目在 `wiki/projects/<项目名>.md` 维护笔记
- 内容：维护者风格、测试命令、踩过的坑、架构要点
- 每轮贡献结束时更新笔记
