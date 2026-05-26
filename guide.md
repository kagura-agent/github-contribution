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
4. **Upstream 已自行修复** — 对策：提 PR 前 `git fetch upstream && git log --oneline upstream/main -20` 检查最近提交，看是否已有同方向改动。**还要检查 upstream 分支**（见 rule #27）

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

14. **Test the exact repro from the issue, not just your own test case** — multica#1995 教训：issue 报告的 repro 是 `--token mul_xxx`（空格形式），但只测了 `--token=mul_xxx`（等号形式）。maintainer 的 #2017 覆盖了两种形式+更新文档+加回归测试。原则：**issue 里的 repro 命令/步骤是你的第一个 test case**。实现修复后，逐行对照 issue 原文的 repro steps 验证。常见错误是「在自己构造的简化 test case 上验证通过就提交」，而 issue reporter 的实际用法恰好是你没覆盖的 variant。推广：CLI 修复必须测所有接受的语法形式（`--flag=val`、`--flag val`、`-f val`）；API 修复必须测 issue 里的 request body（不是自己简化的版本）；配置修复必须测 issue 里贴的原始 config

15. **Security-sensitive data: remove, don't redact** — NemoClaw#2468 教训：token 泄露到日志，我的方案用 `redact()` 遮罩（`****`），维护者的方案直接从输出中移除 token，改用单独的 CLI 命令按需查看。原则：redaction 仍然泄露结构信息（长度、前缀），对 credentials/tokens/passwords，**完全移除 + 独立检索通道** 比 inline masking 更安全。推广：任何处理敏感数据的 PR，问自己「这个数据是否真的需要出现在这个输出中？」如果答案是 no，移除它并提供替代检索方式，而不是遮罩它

16. **Use existing runtime context flags, don't hardcode search order** — openclaw#77247 教训：npm channel plugin 在 dist/ 找不到 contract 文件，我的方案是简单 fallback（先搜 rootDir 再搜 dist/），维护者的方案用已有的 `RUNNING_FROM_BUILT_ARTIFACT` 常量来决定搜索顺序（built artifact → dist/ 优先，source → rootDir 优先）。原则：修 path resolution / resource lookup 时，**先搜 codebase 有没有已有的 runtime context 标志**（build mode、env flag、config constant）来决定行为，不要 hardcode 固定优先级。判断方法：`grep -r "RUNNING_FROM\|BUILD_MODE\|IS_DEV\|__dirname" src/` 找已有的环境感知机制。推广：任何「多个 candidate 位置取一个」的逻辑，问自己「有没有已有的上下文能告诉我哪个是对的？」

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
**当前黑名单：** mastra-ai/mastra（intojhanurag 批量关闭 7 个 PR，明确 "No AI serving PRs"）、jarrodwatts/claude-hud（repo 不 merge 外部 PR，5+ PRs 零 review 持续 2+ 周，最终全部关闭 2026-05-11）

## 知识积累

- 每个贡献过的项目在 `wiki/projects/<项目名>.md` 维护笔记
- 内容：维护者风格、测试命令、踩过的坑、架构要点
- 每轮贡献结束时更新笔记

17. **Parent-child API: breadcrumb over inline** — multica#2088 教训：`GetProject` 返回值里直接内联了 `resources []ResourceRef` 子集合（9 行改动），维护者 supersede 后改为标量 `resource_count` breadcrumb（231 行，7 文件）。原则：当父实体需要暴露子资源的存在性时，**用 count/exists 信号，不要内联完整子集合**。内联 = 紧耦合 + schema debt（每新增一种子资源类型都污染父 schema）；breadcrumb = 松耦合 + 前向兼容。判断方法：问自己「这个子集合未来会增长吗？」如果会，内联就是在给未来的 breaking change 埋雷。推广：任何 REST API 修改，如果涉及把一个 endpoint 的数据嵌入另一个 endpoint 的 response，先考虑是否用引用/计数代替

19. **Check repo contribution gates before first commit** — NemoClaw DCO 教训（2 次 force-push 补 `Signed-off-by`）：部分 repo 要求 DCO signoff、CLA 签署、commit message 格式（Conventional Commits）、或 PR template 必填项。**第一次给新 repo 提 PR 前**，检查：(1) `grep -ri 'DCO\|sign.*off\|certificate.*origin' CONTRIBUTING* .github/ DCO*` (2) `grep -ri 'CLA\|contributor.*license' CONTRIBUTING* .github/` (3) 看最近 merged PR 的 commit message 格式。如果要求 DCO，所有 commit 必须 `git commit --signoff`（或 `-s`）。如果已有 commit 漏了，`git rebase --signoff HEAD~N` 批量补。**项目笔记里记录**这个 repo 需要什么 gate，下次不用重查。推广：任何「CI/bot 挡住的非代码问题」，第一次遇到就记录到项目笔记，不要靠记忆

20. **大 repo 预检 + OOM 防护** — eliza (648MB) + qwen-code (120MB OOM) + gaia (partial clone) 教训：在 workloop 里现 clone 大 repo 浪费整轮时间，且机器内存有限时 full clone 会被 SIGKILL。前置检查：`gh api repos/OWNER/REPO --jq '.size'`（单位 KB），>200000（200MB）的 repo 需要提前 clone 或在非高峰时段准备好本地 repo。**OOM 防护**：当 full clone 被 kill 或机器内存紧张时，使用分级 clone 策略：(1) **Partial clone**（首选）：`git clone --filter=blob:none <url>` — 只下载 tree 结构，blob 按需拉取，适合需要 git history 的场景 (2) **Shallow + sparse**（最省资源）：`git clone --depth 1 --sparse <url>` + `git sparse-checkout set <dirs>` — 只下载指定目录的最新版本，适合只需改特定文件的 PR (3) **GitHub API 直接 push**（clone 完全不可行时）：用 `gh api` 读文件 + create blob/tree/commit/ref 直接在远端提交，零本地磁盘开销。判断方法：>100MB 的 repo 默认用 partial clone；>500MB 或内存 <4GB 可用时用 shallow+sparse。**项目笔记记录 clone 方式**（full/partial/sparse/API），下次直接复用，不重新试错。注意：sparse checkout 的 repo 无法 `git push`（缺少 objects），需要用 GitHub API 推送或先 `git sparse-checkout disable` 拉取完整数据。

21. **Triage reviewer feedback: must-fix → should-fix → defer** — memex#123 教训：reviewer 给了多条 feedback（bug、DRY 重构、self-reference guard、organize.ts 一致性、.gitattributes），全部一次性处理既慢又容易漏，且会膨胀 PR scope。原则：收到 review 后先把所有 comment 分三档：(1) **Must-fix**（影响正确性的 bug — 必须本轮修）(2) **Should-fix**（提升代码质量但不影响功能 — 尽量本轮修，同一 push）(3) **Nice-to-have**（风格偏好、refactor 建议 — 明确回复「deferred to follow-up PR」，不硬塞进当前 PR）。回复 reviewer 时按档位说明每条 feedback 的处置（修了 / 推迟 + 理由），让 reviewer 一眼看到你认真对待了每条意见。好处：PR 不膨胀、review 轮次少、reviewer 信任度高。推广：任何「一次收到 ≥3 条 review comment」的情况都适用这个分诊流程

22. **Forward-compat PRs have a shelf life in fast-moving repos** — openclaw#79755 教训：提了一个 gemini-3-flash-preview 的 forward-compat fix，等 review 期间 upstream 直接加了 native 支持，rebase 后 PR 变多余，只能 self-close。原则：对于日均多次 commit 的活跃 repo（openclaw、vercel/ai 等），**forward-compat / feature-anticipation 类 PR 的保鲜期极短**（3-5 天）。如果 repo 的 release cadence 是每周或更频繁，你的「提前兼容」PR 大概率会在 review 前被 native 实现淘汰。判断方法：提交前检查 `git log --oneline upstream/main --since='7 days ago' | wc -l`，如果 >20 commits/week，forward-compat PR 的预期收益很低。**替代策略**：(1) 改提 issue 而非 PR（"hey, X model needs support"，让维护者自己加）(2) 只提已存在 bug 的修复，不提「预防性兼容」(3) 如果一定要提，PR 描述中注明「this is a stopgap until native support lands」，降低维护者的 review 优先级预期。推广：任何「为未来可能的问题提前打补丁」的 PR，都要评估 repo 的自愈速度——如果 repo 自己解决的速度比 review 快，你的 PR 就是注定浪费的

23. **Upstream CI failures: verify once, document, stop re-analyzing** — hermes-agent 教训（5 PRs × 3 天 × 3 轮/天 = ~45 次重复分析同样的 CI 红灯）：当 PR 的 CI 失败不是你的代码造成的，**只分析一次**，之后不再每轮重复。流程：(1) 首次发现 → `git diff upstream/main -- <failing_test_files>` 确认你没碰过那些文件 (2) 在 PR 下 comment 一次："CI failures in X tests are pre-existing upstream issues, unrelated to this change" (3) 在项目 wiki 笔记标注 `CI: upstream broken since YYYY-MM-DD, affects: [test names]` (4) 后续 patrol 跳过这些已知 CI 问题，只关注**新增的**失败。判断方法：如果上一轮 patrol 已经分析过同一组 CI 失败且结论是 upstream，直接标注 "known upstream CI" 跳过。**重新分析的触发条件**：upstream main 有新 commit（可能修了 CI）、或你 rebase 了（可能引入新冲突）。推广：任何「已确认非我方问题」的重复检查，第一次验证后转为被动监控，不主动每轮分析


24. **Fill PR templates immediately — compliance bots have short timers** — opencode#26641 教训：repo 有 GitHub Actions compliance bot，PR 不填 template 2 小时内自动关闭。原则：**提 PR 后立刻检查** PR description 是否有 template sections（## Summary, ## Changes, ## Testing 等），如果有空白 section 立即填写。判断方法：`cat .github/pull_request_template.md` 看必填项，或看 PR 创建后 bot 的第一条 comment。对于有严格 compliance bot 的 repo（opencode、vercel/ai 等），在项目笔记里标注 `PR template: strict, auto-close after Xh`，下次不踩同一个坑

25. **Avoid "slop" perception — demonstrate domain understanding** — vscode-icons#4040 教训：maintainer @remcohaszing 看到 PR 是 bot 提的，直接关闭并标注 "slop"。原因：PR 做了多件事但没提供上下文引用（为什么要加这些文件扩展名？哪个 issue 或用户报告触发的？）。原则：对于**成熟、低 issue 数量、maintainer 敏感的 repo**，PR 必须展示深度理解：(1) 引用具体 issue 或用户报告 (2) 解释为什么这个改动是需要的（不是 "I noticed X is missing" 而是 "Users reported X in issue #N") (3) 保持 PR 范围极小且单一。如果找不到相关 issue 或用户反馈作为依据，**不要提这个 PR**——它可能确实不需要。推广：任何 repo 如果 maintainer 在 profile/README/CONTRIBUTING 中表达过对 AI PR 的不满，直接 blocklist

27. **Check upstream branches, not just main, before starting work** — multica#2376 + hermes-agent#23173 教训：rule #4 说检查 `git log upstream/main -20`，但维护者经常在**feature branch**上已经开始修同一个问题（multica 的 `upstream/agent/j/encoding-fix-v2`），或者在最近的 commit 中做了重构导致你的 fix 目标函数已被重命名/删除（hermes-agent 把 `_cprint` 重构为 `_prompt_text_input_modal`）。原则：**开工前不仅查 main 的最近提交，还要查 upstream 的活跃分支**。流程：(1) `git fetch upstream` (2) `git log --oneline upstream/main -20` 检查 main (3) `git branch -r --list 'upstream/*' | grep -i '<keyword>'` 检查是否有与你要修的 issue 相关的分支名 (4) 如果发现相关分支且有近期 commit，**放弃这个 issue**（guide rule #9: supersede = 浪费）。判断方法：如果 upstream 有一个分支名包含 issue 编号或相关关键词，且最近 7 天有 commit，大概率维护者在做了。推广：对活跃 repo（>5 commits/week），upstream branch scan 应该成为 workloop issue_select 的标准步骤

26. **Respect repo file conventions: size limits and mode bits** — opc#15-18 教训（4 PRs superseded）：内容全部被 apply 到 main，但被重新打包：测试文件过大（364-525 行）被拆成小文件（repo 有 file-size 规则），docs 文件 mode 从 644 变 755 被还原（非可执行文件不应改 mode）。原则：**提交前检查 repo 的 lint/CI 规则和最近 merge 的 PR 风格**。(1) `git diff --stat` 检查是否有无意的 mode 变更（`100644 → 100755`），如果有，`git update-index --chmod=-x <file>` 还原 (2) 看 repo 已有文件的大小范围，测试文件遵循同样的粒度（如果 repo 里每个 test 文件 <200 行，不要提交 500 行的） (3) `cat .editorconfig .prettierrc .eslintrc* 2>/dev/null` 了解格式规范。推广：工作被认可但包装被拒 = 最可惜的 supersede 类型——花 2 分钟预检可以完全避免

28. **Agent ecosystem is saturated with contributors** — 2026-05-13 观察：openclaw, ClawX, multica, cc-connect, open-cowork 等 agent 方向的热门 repo，每个 bug issue 在发布后数小时内就有竞争 PR。在这些 repo 里选 issue 的窗口期极短。策略调整：(1) 设置 GitHub notification 监控重点 repo 的新 issue，第一时间响应 (2) 在已有 merge 的 repo（multica、openclaw）等待新 issue 而非强行找旧 issue (3) 对于 batch-merge 风格的 repo（如 cc-connect），在 merge batch 后的第一波新 issue 是最佳窗口 (4) 考虑扩展到非 agent 但技术对齐的 repo（Go/TypeScript 工具链）降低竞争。推广：当发现某个赛道的 issue 竞争烈度持续上升，应该**调整赛道**而不是更快地刷同一批 repo

30. **Real-time issue monitoring via GitHub Watch** — 竞争 PR 教训（guide #28）：热门 repo 的 issue 窗口期极短，必须第一时间知道新 issue。设置：对重点 repo（有 merged PR 或持续关注的）用 GitHub Watch 订阅：`echo '{"subscribed":true,"ignored":false}' | gh api -X PUT "/repos/OWNER/REPO/subscription" --input -`。当前已订阅：openclaw, opencode, NemoClaw, hermes-agent, Archon, multica, cc-connect, vercel/ai。效果：新 issue 会出现在 `gh api notifications` 中，被 github-patrol cron 自动捕获。维护：新 merge 一个 repo 的 PR 后，加入 watch 列表；repo 退出/blocklist 后取消订阅（`gh api -X DELETE "/repos/OWNER/REPO/subscription"`）

31. **Verify the bug exists in production code, not just in your test** — multica#2571 教训：测试环境缺少 listener 注册，导致看似 creator 订阅逻辑不存在，实际上 `subscriber_listeners.go` 已有完整实现。原则：提 bug-fix PR 前，先在生产代码中确认 bug 存在——**搜索相关关键词看是否已有处理逻辑**（`grep -r "subscribe\|listener\|creator" src/`）。测试环境的行为 ≠ 生产行为：测试可能缺少 mock、缺少初始化步骤、或使用简化配置。判断方法：如果你只在测试中观察到 bug 但没有 issue 报告，先质疑测试环境而不是生产代码。推广：任何“我发现了一个没人报的 bug”的情况，都要额外谨慎——要么你发现了真正的空白，要么你的环境有问题

32. **Test at the consumer-facing surface, not the internal adapter** — openclaw#81604 教训：Telegram CLI `thread-create` dispatch 失败，我的 PR 测了内部 `channel-actions.ts` adapter（函数本身没问题），维护者的 PR 测了导出的 `telegramPlugin.actions.resolveCliActionRequest`（实际断裂的路径——wrapper 没转发方法）。原则：**测试应覆盖用户/调用者实际使用的 API surface**，不是底层实现。如果 bug 是因为 wrapper/forwarding/re-export 缺失导致的，测 wrapper 层（证明集成路径通了），而不是测 wrappee（底层本来就没坏）。判断方法：问自己「调用者是通过哪个入口触发这个功能的？」，测那个入口。推广：plugin 架构中修 bug 时，测试优先覆盖 plugin 的 exported interface → adapter layer → internal function，从外到内。如果只测最内层，即使测试全绿，wrapper 层的断裂仍然不会被捕获

33. **Grep the reported error string before deep-diving** — opencode#27946 教训：花了 20 分钟研究 `[MaxDepth]` 泄漏 bug，结果这个字符串在整个 codebase 和所有依赖中都不存在，无法复现。原则：**issue 里提到具体错误消息/字符串时，第一步永远是 grep**。`grep -r "ErrorString" . && grep -r "ErrorString" node_modules/` （或等价搜索）。如果 0 结果 → 这个 bug 大概率是 (1) 特定版本/环境独有 (2) 已在 HEAD 修复 (3) 来自未公开的 fork/plugin。判断方法：5 分钟内完成 grep + `git log --all --grep="keyword"` 搜索，如果找不到目标字符串/函数，**立即放弃**，不要用「也许运行时动态生成」合理化继续投入。推广：任何 fix 的第一步都应该是定位目标代码——如果定位不到，就不该开始修

34. **Check evidence requirements before starting platform-specific PRs** — openclaw#82128/#83084/#83378 教训（3+ PRs 卡在 "Real behavior proof" CI gate 多日）：部分 repo 有 CI 或 bot 门控，要求 PR 附带真实运行时证据（截图、日志、录屏），不只是测试通过。对于平台特定路径的 fix（Telegram forum topic、Slack DM thread 等），如果你本地没有对应平台环境，证据无法产出，PR 就会无限期卡在 CI gate。原则：**开工前确认 repo 的 CI/bot 证据要求**：(1) 查 `.github/workflows/` 和最近 PR 的 bot 评论，看有没有 "behavior proof" / "real evidence" / "screenshot required" 类 gate (2) 如果有，评估你能否在本地复现该场景（你有 Telegram bot token？有对应的 forum topic？有 Slack workspace？） (3) 如果不能产出证据，有两个选择：a) 在 PR 描述中明确写 "I cannot produce live evidence for this platform path — requesting proof:override" 并提供代码路径追踪 + 单元测试作为替代 b) 跳过这个 issue，选一个你能端到端验证的。判断方法：如果 fix 涉及的 channel/platform 你没有测试环境（没有 bot token / 没有对应 workspace / 没有 forum topic），默认选择 (b) 跳过。推广："能写代码" ≠ "能交付 PR"——交付包括满足 repo 的所有 gate，不只是测试通过

35. **Check issue duplicate/cross-reference status before starting work** — NemoClaw#3722 教训：issue #3719 的 fix 质量很高（maintainer praised），但 issue 本身是 #3704 的 duplicate，PR 因此被关闭。时间浪费在一个「正确的修复 for 重复的 issue」上。原则：**开工前检查 issue 的 cross-references 和标签**。流程：(1) 看 issue 的 label 是否有 `duplicate`、`wontfix`、`stale` (2) 看 issue body 和 comments 是否有 "duplicate of #N"、"same as #N"、"related to #N" (3) `gh api repos/OWNER/REPO/issues/N/timeline --paginate | jq '.[] | select(.event=="cross-referenced")'` 查看是否有其他 issue/PR 引用了同一个问题 (4) 如果 issue 很新（<24h），看 issue list 有没有同名/类似描述的 issue（用 `gh issue list -s open --search "keyword"`）。判断方法：如果 issue 有 ≥1 个 cross-reference 指向同一个 bug 且那个 issue 更早/更详细，考虑转去那个 issue 贡献，或在 comment 确认是否 dup 后再开始。推广：issue 的 metadata（label、timeline、cross-refs）是免费信息，花 30 秒查可以省 30 分钟白做

36. **Batch similar mechanical fixes into a rollup PR** — hermes-agent#12038 教训（24 个 exc_info 修复分别提了独立 PR，maintainer 合成 rollup #15483 后关闭所有）：当你发现同一类机械修复（如 `logger.error(msg)` → `logger.error(msg, exc_info=True)`）散布在多个文件时，**不要每个文件开一个 PR**——维护者会把它们合成 rollup 并关闭你的。原则：**同类机械修复 → 一个 rollup PR**。判断方法：如果你的修改模式可以用 sed/grep 一行描述（如 "add exc_info=True to all logger.error calls"），它就是机械修复，应该合并。流程：(1) 全 repo grep 找出所有同类问题 `grep -rn 'logger.error(' --include='*.py' | grep -v exc_info` (2) 一次性修复所有 (3) 一个 PR，title 说明覆盖范围（"fix: add exc_info=True to all N logger.error calls"）(4) PR body 按文件列出每处改动。推广：任何「N 个文件 × 同一个 pattern」的修复都应该是 1 个 PR，不是 N 个 PR。N 个 PR = N 倍 review 负担 = 维护者替你合成 = 你被 supersede

37. **Some repos require claiming issues before work** — NemoClaw#3836 教训：直接提 PR 没先 claim issue，maintainer 要求先留言等 assign。**这不是通用规则，是 repo-specific 要求**。正确做法：把每个 repo 的贡献流程记在项目笔记里（如 `wiki/projects/nemoclaw.md` → "必须先 claim issue"），打工前读项目笔记。大型 repo（NemoClaw、OpenClaw）更可能有正式流程

29. **Anti-AI sentiment is spreading** — mcp-use#1486 显示 repo 正在主动建设 anti-AI-PR 工具。趋势：越来越多 repo 开始对 bot PR 设防（vscode-icons 直接标 slop、mastra 批量关闭、mcp-use 建设自动化检测）。应对：(1) 贡献质量必须远超 "slop" 水平——有上下文引用、精确修复、测试覆盖 (2) 每次提 PR 前检查 repo 是否有 anti-AI 信号（CONTRIBUTING.md、recent closed PRs、issue discussions）(3) 在已建立信任的 repo 深耕 > 广撒网

38. **Check issue-assignment gates before opening PRs** — deepagents #3565 教训：PR 被 check-issue-link bot 自动关闭，因为"PR author must be assigned to the linked issue"。部分 repo 有 CI/bot gate 要求 PR author 先被 assign 到 linked issue 才允许 PR 存在。**新 repo 首次 PR 前**检查：(1) `.github/workflows/` 搜索 `issue-link` / `check-issue` / `require-assignment` 关键词 (2) 看最近 closed PR 是否有 bot 自动关闭的 pattern。如果发现 assignment gate：先在 issue 下留言请求 assign（"Could I be assigned to this?"），等 maintainer 响应后再开 PR。**项目笔记里记录**这个 gate 存在，下次不踩

40. **Honor your assignments — assigned issues are commitments** — NemoClaw#4236 教训：在 issue 下评论请求 assign，被 assign 后忘了，几天后 Luna 问才发现没跟进。被 assign = 承诺做，不做 = 失信。每轮打工 followup 第一步就是 `gh search issues --assignee=kagura-agent --state=open`，检查有没有被 assign 但没开工的 issue。有 → 本轮优先做，不找新活。不打算做了 → 去 issue 下说明并让 maintainer 取消 assign，不要静默放弃。

39. **APPROVED PRs rot fast — rebase and ping proactively** — qwen-code#4459 教训：PR 获得 wenshao APPROVED，但只有 maintainer 能 merge，等待期间 repo 持续大量 commit，100+ conflicts 累积到无法 rebase，最终只能 self-close。所有代码工作、review 回复、测试覆盖全部白费——不是因为方案错，而是因为 merge 窗口过了。原则：**APPROVED ≠ 会被 merge**。获得 approval 后立即进入「merge 护航」模式：(1) **当天 ping**——approval 后 24h 内如果没 merge，礼貌 ping maintainer 请求 merge (2) **持续 rebase**——活跃 repo（>5 commits/day）每 3 天 rebase 一次，普通 repo 每周一次，不管有没有 conflict (3) **conflict 阈值**——如果 rebase 后 conflict 超过 ~20 个文件，评估是否值得继续（可能开 fresh PR on latest main 更快）(4) **7 天规则**——APPROVED 超过 7 天未 merge 且 ping 无回应，考虑在 PR 里 @ 其他 maintainer 或在 issue 中说明紧迫性。判断方法：`git fetch upstream && git merge-base --is-ancestor HEAD upstream/main` 检查是否 behind main；`git diff upstream/main --stat | tail -1` 看 divergence 程度。推广：任何需要他人操作才能完成的 PR（merge 权限、CI 手动触发、label 添加），approval 后不能进入被动等待——主动推进是你的职责，不是 maintainer 的

41. **Reply ≠ resolution — CHANGES_REQUESTED needs a push, not a comment** — qwen-code#4474 教训：wenshao 给了 CHANGES_REQUESTED，我回了"会改"但没 push 代码。去重规则看 last comment 是 kagura-agent → 判定球在对方 → 跳过。实际代码没改，球在我手里。原则：**review 状态是最高优先级信号**。CHANGES_REQUESTED 只有 push 新 commit 才算处理，comment 回复"我会改"不算。followup 去重规则：先查 review 状态，再查 comment 归属。review 是 CHANGES_REQUESTED 且 push 在 review 之前 → 球在我手里，不管 last comment 是谁。
