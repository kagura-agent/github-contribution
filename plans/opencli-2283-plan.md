# Plan: jackwener/opencli#2283 — jd reviews 返回空数组

## 背景
`opencli jd reviews <sku>` 始终返回 `[]`。根因：`clis/jd/reviews.js` 抓 `document.body.innerText` 找"买家评价"锚点，但 JD 新商品页评论区是独立异步模块，不渲染进 DOM/innerText（只有 placeholder"暂无评价，快来抢首评吧"）。真实数据在 `club.jd.com/comment/productPageComments.action?productId=<sku>&score=0&sortType=5&page=0&pageSize=N`，且该 API 无登录态时被风控（curl 实测返回"系统繁忙"）。

## 变更清单

### 1. `clis/jd/reviews.js`（核心修复）
重写 `func` 的页面内逻辑：
- 保持 `page.goto(item.jd.com/<sku>.html)` + `page.wait(5)`（确保 cookie 域建立）
- 改为在 `page.evaluate` 内用 `fetch` 调 comment API（`credentials: 'include'`，复用浏览器登录 cookie）：
  `https://club.jd.com/comment/productPageComments.action?productId=${sku}&score=0&sortType=5&page=0&pageSize=${limit}`
- 解析响应 JSON：`comments` 数组，字段 `content`/`nickname`/`creationTime`
- 映射输出 columns `['rank', 'user', 'content', 'date']`：rank=序号、user=nickname、content=content、date=creationTime
- 错误处理：
  - fetch 失败/非 JSON → 返回结构化错误（沿用现有 CommandExecutionError 模式）
  - API 返回空 comments（风控/未登录信号）→ 在 evaluate 外检查 `page.getCookies` 是否有 pin/thor cookie；无 cookie → 抛 `AuthRequiredError`（提示 `opencli jd login`）；有 cookie 但 API 空 → 返回空数组（该商品可能真没评论）
- 保留 `normalizeNumericId` + `clampInt`（limit 1-20 不变）

### 2. `clis/jd/commands.test.js`（新增测试）
- 新增 `jd reviews` 测试组：
  a. 正常路径：mock evaluate 返回 comments JSON → 断言输出映射正确（user/content/date）
  b. 未登录路径：mock evaluate 返回空数组 + getCookies 返回空 → 断言抛 AuthRequiredError
  c. sku 非法：`reviews.func(page, {sku:'abc'})` → 抛 ArgumentError（沿用现有 pattern）
- 用现有 `createPageMock`（clis/test-utils.js）

## 实现方法
- 参考已有 pattern：CONTRIBUTING.md 的 func() 示例（page.evaluate 内 fetch + credentials include）、`clis/douyin/_shared/browser-fetch.js`（浏览器上下文 fetch + 错误映射）、`clis/jd/auth.js`（pin/thor cookie 检查 + AuthRequiredError）
- 不新增共享模块（避免 scope 膨胀），直接在 reviews.js 内联

## 边界情况
- 只影响 `jd reviews` 一个命令；detail/search/cart 不动
- columns 不变 → 不需要重新 build cli-manifest.json
- 输出结构向后兼容（rank/user/content/date 与现状一致）

## 测试策略
- `npx vitest run --project adapter clis/jd/`（21 现有测试 + 新增）
- 全量 `npm test` 确认无回归（基线 591 files / 6734 tests）
- 本地 curl 已实证：无登录态 API 被风控 → 确认 AuthRequiredError 分支必要性

## 风险点
- JD API 响应格式可能含额外字段（score/回复数等）→ 只取需要的字段，容错
- 风控策略可能变化 → cookie 检查是最小可靠信号
- maintainer 可能偏好"点击买家评价 tab 触发渲染"方案而非 API → 但 issue 作者已实测点击 tab 后 innerText 仍是 placeholder，API 方案更可靠；PR 描述中说明取舍
