# Log: các lần chạy Codex thất bại

> **Đây KHÔNG phải một review.** File này chỉ là transcript thô của những lần gọi Codex
> không ra được kết quả. Trước đây nó nằm ở `docs/reviews/repo-structure-round-0.md`,
> tức đúng vùng tên mà cổng review đọc — khiến vòng 0 trông như đã có review trong khi
> chưa hề có. Chuyển ra đây theo finding #4 vòng 1.
>
> Review thật của skeleton Stage 0: `docs/reviews/repo-structure-round-1.md`.

## 2026-10-14 — `/codex:review --base master` (lần 1 và 2)
Hai nguyên nhân chồng nhau:
1. **Mất mạng** — hàng chục dòng `Reconnecting... waiting for network`.
2. **Model không dùng được** — `404 Not Found: 模型 gpt-6-sol 不在当前 API Key 的可用模型范围内`,
   endpoint `http://localhost:51692/v1/responses`.

Ngoài ra lần 1 và 2 còn chạy sai target: lúc đó đang đứng trên nhánh `master` nên
`master...HEAD` rỗng — kể cả chạy được cũng không có gì để review. Chỉ sau khi tách
nhánh `stage-0/skeleton` và commit thì diff mới có nội dung.

---

## Transcript thô

```
OpenAI Codex v0.162.1
--------
workdir: /Users/floral/Documents/Floral's Projects/learning-lingua
model: gpt-6-sol
provider: cockpit
approval: never
sandbox: read-only
reasoning effort: medium
reasoning summaries: none
session id: 01a139c0-7f51-7fb2-a9d2-26da08c38aaf
--------
user
current changes
ERROR: Reconnecting... waiting for network
ERROR: Reconnecting... waiting for network
ERROR: Reconnecting... waiting for network
ERROR: Reconnecting... waiting for network
ERROR: Reconnecting... waiting for network
ERROR: Reconnecting... 1/5
ERROR: Reconnecting... 2/5
ERROR: Reconnecting... 3/5
ERROR: Reconnecting... 4/5
ERROR: Reconnecting... 5/5
ERROR: unexpected status 404 Not Found: 模型 gpt-6-sol 不在当前 API Key 的可用模型范围内, url: http://localhost:51692/v1/responses
codex
Review was interrupted. Please re-run /review and wait for it to complete.
ERROR: unexpected status 404 Not Found: 模型 gpt-6-sol 不在当前 API Key 的可用模型范围内, url: http://localhost:51692/v1/responses
```
