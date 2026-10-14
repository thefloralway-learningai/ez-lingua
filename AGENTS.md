# AGENTS.md — nguồn chung cho mọi agent

> **Quy tắc truy vết — áp cho chính file này.**
> Mọi quyết định hoặc luật trong AGENTS.md phải trỏ tới nguồn: một ADR
> (`docs/decisions/ADR-<nnnn>-*.md`) hoặc một file review (`docs/reviews/*.md`).
> **Không ghi quyết định nào không có nguồn.** Mục chưa có nguồn phải mang dấu
> **⚠ chưa có nguồn** cho tới khi được ghi vào ADR — và không được coi là đã chốt.
> Nguồn: ADR-0001 §C13.

## Mục đích repo
Repo thử nghiệm để học AI-native SDLC: multi-agent, subagent, skill, hook.
Sản phẩm đích là một app học tiếng Anh từ vựng theo ngữ cảnh (ý tưởng thô:
`docs/ideas/00-raw-idea.md`). Quy trình quan trọng ngang sản phẩm — mọi điều rút ra
ghi vào `docs/learning-log.md`. Câu hỏi nghiên cứu: xem `README.md`.

## Giai đoạn hiện tại: STAGE 0 xong — CHƯA CÓ CODE
Repo mới chỉ có khung tài liệu. Bước kế tiếp là **Stage 1 (Plan)**.
KHÔNG tạo `src/`, không chọn framework, không cài dependency, không viết code
cho đến khi `docs/requirements.md` **và** `docs/design.md` đều có `status: approved`.
→ ADR-0001 §C8

## Quy trình 6 stage
Tên stage theo README. Không nhảy bước. Mỗi stage kết thúc khi người dùng tự đổi
`status: draft` → `status: approved` trong artifact của stage đó. → ADR-0001 §C9

| # | Stage | Artifact | Ai viết | Ai review | Nguồn |
|---|---|---|---|---|---|
| 1 | Plan | `docs/intent.md` | Claude (skill `product-owner`) | Codex **và** subagent `qa-analyst` | ADR-0001 §P |
| 2 | Design | `docs/requirements.md`, `docs/design.md`, ADR | Claude (vai Architecture) | Codex | ADR-0001 §P |
| 3 | Dev | `docs/tasks.md` → **test viết trước code rồi khóa** → code | Claude Code (vai Dev) | Codex | ADR-0001 §C12 |
| 4 | Test | e2e, eval, báo cáo kiểm thử trong `docs/reviews/` | Codex (vai QA) | Claude | ADR-0001 §P |
| 5 | Deploy | PR, AI review, CI gate | vai DevOps | Bên không viết | ADR-0001 §O2 |
| 6 | Maintain | metric vận hành; vượt ngưỡng → `intent.md` mới | vai Dev | ⚠ chưa có nguồn | — |

Hai điểm dễ nhầm (→ ADR-0001 §P):
- **Test viết ở Stage 3 (Dev), TRƯỚC khi viết code**, rồi khóa — code phải chạy qua test
  đó, không sửa test cho vừa code.
- **Stage 4 (Test) là kiểm thử tổng thể** (e2e, eval, báo cáo), không phải nơi viết unit test.

## Các vai agent
Vai là **kiến thức trong skill**, không gắn chết vào một model. Model nào thực hiện một
vai phụ thuộc quy tắc cross-model review bên dưới. → ADR-0001 §O3

| Vai | Việc | Kiến thức ở | Trạng thái |
|---|---|---|---|
| Product Owner | Brainstorm, phản biện ý tưởng, viết `intent.md` + `requirements.md` | `.agents/skills/product-owner/` | ✅ có |
| QA | Kiểm AC test được, AC coverage, báo cáo issue | `.agents/skills/qa-review/` | ✅ có |
| Architecture | Thiết kế hệ thống, chọn tech stack, viết `design.md` | `architecture-review/` | ⏳ Stage 2 |
| Security | Review bảo mật, dữ liệu người dùng không lộ ra ngoài | `security-review/` | ⏳ Stage 2 |
| Dev | Sinh mã theo `tasks.md`, và vận hành ở Stage 6 | chưa có | ⏳ Stage 3 |
| DevOps | PR, CI gate, triển khai | chưa có | ⏳ Stage 5 |

**QA là MỘT vai duy nhất**, kiến thức ở skill `qa-review`. Chỉ *người thực hiện* thay
đổi: Claude viết → Codex làm QA; Codex viết → subagent `qa-analyst` làm QA. Stage 1 là
ngoại lệ có chủ đích: **cả hai cùng review** để so sánh (câu hỏi nghiên cứu #4 trong
README). → ADR-0001 §O3

**Vai Dev chạy trên Claude Code ở giai đoạn đầu** — không phải vì Claude viết code tốt
hơn, mà vì hook, permission và subagent hiện chỉ tồn tại trong `.claude/`, nên chỉ ở đó
mới ràng buộc được "test khóa trước khi viết code". Codex review code. **Xem xét lại khi
`harness/gates/` + CI đã chạy** — lúc đó ràng buộc nằm ở gate, không còn phụ thuộc công
cụ nào. → ADR-0001 §C12

### Luồng phối hợp — ⚠ chưa có nguồn (suy ra từ bảng 6 stage, chưa ai duyệt riêng)
```
Product Owner  ──► docs/intent.md ──► docs/requirements.md
      └─► Architecture ──► docs/design.md + ADR
            └─► Dev ──► docs/tasks.md ──► test (khóa) ──► code
                  └─► QA ──► e2e, eval, issue vào docs/reviews/
                        └─► Security ──► review dữ liệu từ vựng người dùng
                              └─► DevOps ──► PR, CI gate, deploy
                                    └─► Dev ──► metric; vượt ngưỡng → intent.md mới
```

### Điểm đặc thù của app học tiếng Anh — ⚠ chưa có nguồn
Giả định sản phẩm lấy từ README gốc, **chưa qua Stage 1**. Đừng coi là yêu cầu.
- **PO** cần brainstorm kỹ: ai là người dùng, flow tra từ → tạo bài học → ôn tập ra sao.
- **QA** kiểm: flashcard sinh ra có đúng ngữ cảnh không, spaced repetition có chạy không.
- **Security** đảm bảo: từ vựng và ngữ cảnh người dùng nhập không bị lộ ra ngoài.

## Quy tắc
- **Không bao giờ tự đổi `status` sang `approved`.** Chỉ người dùng làm. Hook
  `.claude/hooks/protect-approved.sh` chặn sửa file đã approved. → ADR-0001 §C9
- **Model nào viết thì model kia review.** Agent không tự review sản phẩm của chính nó.
  → ADR-0001 §P
- Mỗi quyết định kiến trúc hoặc quy trình ghi thành ADR trong `docs/decisions/`
  (`ADR-<nnnn>-<slug>.md`), theo `docs/templates/adr.md`. → ADR-0001 §C13
- Mọi artifact viết từ template: `.agents/skills/product-owner/templates/` (intent,
  requirements), `docs/templates/` (adr, review). Giữ nguyên ID (`US-xx`, `AC-xx.y`,
  `NFR-xx`) khi sửa. — ⚠ chưa có nguồn (kế thừa từ `reference/asdlc-starter`)
- Không bịa thông tin người dùng chưa nói. Thiếu → ghi vào "Câu hỏi mở".
  — ⚠ chưa có nguồn (kế thừa từ `reference/asdlc-starter`)
- Tài liệu viết **tiếng Việt**; tên file, ID, frontmatter, tên test, code: **tiếng Anh**.
  — ⚠ chưa có nguồn (yêu cầu người dùng ở Stage 0, chưa ghi ADR)

### Artifact đặt ở đâu → ADR-0001 §O6
`docs/` **phẳng**: `docs/intent.md`, `docs/requirements.md`, `docs/design.md`,
`docs/tasks.md`. Chuyển sang `docs/<feature>/` khi có tính năng thứ hai — không sớm hơn.

### Review đặt tên theo artifact → ADR-0001 §O7
`docs/reviews/<artifact>-round-<n>.md`, theo `docs/templates/review.md`.
`<artifact>` ∈ `repo-structure`, `intent`, `requirements`, `design`, `tasks`.
Tên theo artifact chứ không theo stage, vì một stage có thể sinh nhiều artifact.
Nhiều reviewer cùng một vòng → **ghi issue tách theo reviewer**, mỗi reviewer một bảng.

### Ngưỡng dừng vòng review → ADR-0001 §O8
> **Giá trị ban đầu**, chỉnh theo những gì ghi trong `docs/learning-log.md`.

Mặc định mọi vòng: **0 blocking, ≤2 major, tối đa 3 vòng**. Thêm gate riêng:

| Artifact | Gate bắt buộc |
|---|---|
| `requirements.md` | QA đặt được tên test cụ thể cho **100% AC** |
| `design.md` | Mọi AC có tầng test tương ứng; mọi lựa chọn stack có ADR |
| code (Stage 3) | test / lint / SAST đều pass |

## Bản đồ thư mục → ADR-0001 §C1, §C2, §C4, §C7
- `AGENTS.md` — file này, nguồn chung cho cả Claude và Codex.
- `README.md` — mô tả repo, câu hỏi nghiên cứu, cấu trúc. Không mô tả lại quy trình.
- `CLAUDE.md` — trỏ về AGENTS.md + phần riêng Claude Code.
- `.agents/skills/` — kiến thức vai trò, dùng chung: `product-owner/`, `qa-review/`.
- `.claude/` — riêng Claude Code: `skills` (symlink → `../.agents/skills`),
  `agents/qa-analyst.md`, `hooks/`, `settings.json`.
- `docs/` — bộ nhớ dự án: `ideas/` (chỉ đọc, không biên tập), `templates/`,
  `decisions/`, `reviews/`, `learning-log.md`.

## Sẽ thêm khi cần — ⚠ điều kiện chưa có nguồn
Việc **hoãn** các hạng mục này: → ADR-0001 §C8. Nhưng từng dòng điều kiện dưới đây do
agent đề xuất ở Stage 0, **chưa ai duyệt riêng** — sửa được, không phải luật.

| Hạng mục | Điều kiện thêm |
|---|---|
| `architecture-review/` + vai Architecture | Khi `docs/intent.md` approved, bắt đầu Stage 2. |
| `security-review/` + vai Security | Khi Stage 2 chốt lưu dữ liệu người dùng ở đâu. |
| Vai Dev (Stage 3 + Stage 6) | Khi `docs/tasks.md` tồn tại. |
| Vai DevOps (Stage 5) | Khi có code chạy được và cần PR/CI thật. |
| Metric Maintain + ngưỡng mở `intent.md` mới | Khi Stage 5 deploy xong lần đầu. |
| `src/` | Khi `requirements.md` **và** `design.md` cùng approved, và test của task đó đã viết xong. |
| `harness/` (`pipeline.yaml`, `run.py`, `gates/`) | Khi đã chạy tay trọn ≥1 vòng stage và các bước lặp đủ ổn định để script hóa. |
| `.github/workflows/gates.yml` | Khi `harness/gates/` đã có ít nhất một script chạy được ở local. |

Thêm hạng mục nào thì ghi ADR kèm lý do.
