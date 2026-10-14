# AGENTS.md — nguồn chung cho mọi agent

> **Quy tắc truy vết — áp cho chính file này.**
> Mọi quyết định hoặc luật trong AGENTS.md phải trỏ tới nguồn: một ADR
> (`docs/decisions/ADR-<nnnn>-*.md`) hoặc một file review (`docs/reviews/*.md`).
> **Không ghi quyết định nào không có nguồn.** Mục chưa có nguồn phải mang dấu
> **⚠ chưa có nguồn** cho tới khi được ghi vào ADR — và không được coi là đã chốt.
> Hiện **không mục nào** mang dấu này (rà soát 2026-10-14, kết quả ở ADR-0001
> § "Mục chưa có nguồn"). Nguồn: ADR-0001 §C13.

## Mục đích repo
Repo thử nghiệm để học AI-native SDLC: multi-agent, subagent, skill, hook. Sản phẩm đích
là app học tiếng Anh từ vựng theo ngữ cảnh (ý tưởng thô: `docs/ideas/00-raw-idea.md`).
Quy trình quan trọng ngang sản phẩm — điều rút ra ghi vào `docs/learning-log.md`.
Câu hỏi nghiên cứu: xem `README.md`.

## Giai đoạn hiện tại: STAGE 0 xong — CHƯA CÓ CODE
Bước kế tiếp: **Stage 1 (Plan)**. KHÔNG tạo `src/`, không chọn framework, không cài
dependency, không viết code cho tới khi `docs/requirements.md` **và** `docs/design.md`
đều có `status: approved`. → ADR-0001 §C8

## Quy trình 6 stage
Tên stage theo README. Không nhảy bước. Mỗi stage kết thúc khi người dùng tự đổi
`status: draft` → `approved` trong artifact của stage đó. → ADR-0001 §C9

| # | Stage | Artifact | Ai viết | Ai review | Nguồn |
|---|---|---|---|---|---|
| 1 | Plan | `docs/intent.md` | Claude (skill `product-owner`) | Codex **và** subagent `qa-analyst` | ADR-0001 §P |
| 2 | Design | `docs/requirements.md` | Claude (skill `product-owner`) | Codex | ADR-0001 §O10 |
| 2 | Design | `docs/design.md` + ADR trong `docs/decisions/` | Claude (vai Architecture) | Codex | ADR-0001 §O10 |
| 3 | Dev | `docs/tasks.md` → **test viết trước code rồi khóa** → code | Claude Code (vai Dev) | Codex | ADR-0001 §C12 |
| 4 | Test | e2e, eval, báo cáo kiểm thử trong `docs/reviews/` | Codex (vai QA) | Claude | ADR-0001 §P |
| 5 | Deploy | PR, AI review, CI gate | vai DevOps | Bên không viết | ADR-0001 §O2 |
| 6 | Maintain | metric vận hành; vượt ngưỡng → `intent.md` mới | vai Dev | không có vòng review riêng¹ | ADR-0001 §C17 |

¹ Maintain không sinh artifact mới để soi, nó sinh *tín hiệu*; vượt ngưỡng thì mở
`intent.md` mới và chạy lại từ Stage 1. **Tạm thời — xem lại khi tới Stage 6.**

Hai điểm dễ nhầm (→ ADR-0001 §P): **test viết ở Stage 3 (Dev), TRƯỚC khi viết code**, rồi
khóa — code phải chạy qua test đó, không sửa test cho vừa code. **Stage 4 (Test) là kiểm
thử tổng thể** (e2e, eval, báo cáo), không phải nơi viết unit test.

## Các vai agent
Vai là **kiến thức trong skill**, không gắn chết vào model nào; ai thực hiện phụ thuộc
quy tắc cross-model review bên dưới. → ADR-0001 §O3

| Vai | Việc | Kiến thức ở | Trạng thái |
|---|---|---|---|
| Product Owner | Brainstorm, phản biện ý tưởng, viết `intent.md` (Stage 1) và `requirements.md` (đầu Stage 2) | `.agents/skills/product-owner/` | ✅ có |
| QA | Kiểm AC test được, AC coverage, báo cáo issue | `.agents/skills/qa-review/` | ✅ có |
| Architecture | Thiết kế hệ thống, chọn tech stack, viết `design.md` + ADR. **Không viết `requirements.md`** | `architecture-review/` | ⏳ Stage 2 |
| Security | Review bảo mật, dữ liệu người dùng không lộ ra ngoài | `security-review/` | ⏳ Stage 2 |
| Dev | Sinh mã theo `tasks.md`, và vận hành ở Stage 6 | chưa có | ⏳ Stage 3 |
| DevOps | PR, CI gate, triển khai | chưa có | ⏳ Stage 5 |

**QA là MỘT vai duy nhất**, kiến thức ở skill `qa-review`; chỉ *người thực hiện* đổi:
Claude viết → Codex làm QA, Codex viết → `qa-analyst` làm QA. Stage 1 là ngoại lệ có chủ
đích: **cả hai cùng review** để so sánh (câu hỏi nghiên cứu #4). → ADR-0001 §O3

**`requirements.md` thuộc vai Product Owner**, tạo ở **đầu Stage 2**, ngay trước khi vai
Architecture bắt tay vào `design.md`: diễn giải `intent.md` thành US/AC là việc sản phẩm,
không phải việc kiến trúc. **Quy trình requirements trong skill `product-owner` sẽ thêm
khi bắt đầu Stage 2**, cùng lúc dựng skill `architecture-review`. → ADR-0001 §O10

**Vai Dev chạy trên Claude Code ở giai đoạn đầu** — không phải vì Claude viết code tốt
hơn, mà vì hook/permission/subagent hiện chỉ có trong `.claude/`, nên chỉ ở đó mới ràng
buộc được "test khóa trước khi viết code". Codex review code. **Xem xét lại khi
`harness/gates/` + CI đã chạy.** → ADR-0001 §C12

### Luồng phối hợp
Đọc bảng 6 stage theo thứ tự — nó chính là luồng. Sơ đồ ASCII cũ đã bỏ vì lặp nguyên nội
dung bảng (ADR-0001 § "Mục chưa có nguồn" U2).

## Quy tắc
- **Không bao giờ tự đổi `status` sang `approved`.** Chỉ người dùng làm. Hai hook chặn:
  `protect-approved.sh` (Edit/Write/MultiEdit — soi cả nội dung sắp ghi) và
  `protect-approved-bash.sh` (lệnh shell). Cả hai **fail closed**. Chúng là lớp
  guardrail **chống nhầm lẫn** trên đường Edit/Write/MultiEdit, không chống agent cố ý.
  Ghi qua Bash nằm **ngoài phạm vi hook** — do `harness/gates/check_status.py` canh.
  Cổng duyệt thật là **merge PR vào `master` do người làm**.
  Test: `tests/hooks/test_protect_approved.sh`.
  → ADR-0001 §C9, §C14, § "Mô hình mối đe dọa"
- **Model nào viết thì model kia review.** Agent không tự review sản phẩm của chính nó.
  → ADR-0001 §P
- Mỗi quyết định kiến trúc hoặc quy trình ghi thành ADR trong `docs/decisions/`
  (`ADR-<nnnn>-<slug>.md`), theo `docs/templates/adr.md`. → ADR-0001 §C13
- Mọi artifact viết từ template: `.agents/skills/product-owner/templates/` (intent,
  requirements), `docs/templates/` (adr, review). Giữ nguyên ID (`US-xx`, `AC-xx.y`,
  `NFR-xx`) khi sửa — ID là thứ review và test trỏ tới. → ADR-0001 §C19
- Không bịa thông tin người dùng chưa nói. Thiếu → ghi vào "Câu hỏi mở".
  → ADR-0001 §C20
- **Chạy `python3 harness/gates/check_status.py` trước khi mở PR.** Gate báo FAIL nếu
  nhánh sửa file đã duyệt trên `master`. → ADR-0001 § "Mô hình mối đe dọa"
- **Bên sửa không được kết luận gate đạt.** Sửa xong thì ghi "đã xử lý n/n" và
  "Gate: chờ round <n+1>" — **vòng review kế tiếp** mới quyết định gate có đạt hay
  không. Lý do: bên vừa sửa là bên ít có khả năng thấy chỗ mình sửa hụt nhất.
  → ADR-0001 §C16
- **Việc tự quyết ngoài yêu cầu phải liệt kê ở cuối báo cáo.** Làm gì mà người dùng
  không nói rõ — chọn một phương án khi đề bài mơ hồ, sửa thêm thứ ngoài phạm vi, bỏ
  bớt nội dung để vừa giới hạn — thì cuối báo cáo liệt kê ra, mỗi việc một dòng kèm lý
  do, để người dùng bác được. Không gộp lẫn vào phần "đã làm". → ADR-0001 §C15
- Tài liệu viết **tiếng Việt**; tên file, ID, frontmatter, tên test, code: **tiếng Anh**.
  → ADR-0001 §C21

### Artifact đặt ở đâu → ADR-0001 §O6
`docs/` **phẳng**: `docs/intent.md`, `docs/requirements.md`, `docs/design.md`,
`docs/tasks.md`. Chuyển sang `docs/<feature>/` khi có tính năng thứ hai — không sớm hơn.

### Review đặt tên theo artifact → ADR-0001 §O7
`docs/reviews/<artifact>-round-<n>.md`, theo `docs/templates/review.md`; `<artifact>` ∈
`repo-structure`, `intent`, `requirements`, `design`, `tasks`. Tên theo artifact chứ
không theo stage, vì một stage có thể sinh nhiều artifact. Nhiều reviewer cùng một vòng
→ **ghi issue tách theo reviewer**, mỗi reviewer một bảng. Transcript của lần chạy
reviewer bị lỗi **không** để trong `docs/reviews/` — đưa vào `docs/logs/`.

### Ngưỡng dừng vòng review → ADR-0001 §O8
> **Giá trị ban đầu**, chỉnh theo `docs/learning-log.md`.

Mặc định mọi vòng: **0 blocking, ≤2 major, tối đa 3 vòng**. Gate riêng thêm:

| Artifact | Gate bắt buộc |
|---|---|
| `requirements.md` | QA đặt được tên test cụ thể cho **100% AC** |
| `design.md` | Mọi AC có tầng test tương ứng; mọi lựa chọn stack có ADR |
| code (Stage 3) | test / lint / SAST đều pass |

Quy đổi mức độ: xem `.agents/skills/qa-review/SKILL.md`. Đó là **nguồn duy nhất** —
đừng chép lại luật quy đổi vào đây hay vào ADR. → ADR-0001 §O11, §C23

## Bản đồ thư mục → ADR-0001 §C1, §C2, §C4, §C7
- `AGENTS.md` — file này, nguồn chung cho cả Claude và Codex.
- `README.md` — mô tả repo, câu hỏi nghiên cứu, cấu trúc. Không mô tả lại quy trình.
- `CLAUDE.md` — trỏ về AGENTS.md + phần riêng Claude Code.
- `.agents/skills/` — kiến thức vai trò, dùng chung: `product-owner/`, `qa-review/`.
- `.claude/` — riêng Claude Code: `skills` (symlink → `../.agents/skills`),
  `agents/qa-analyst.md`, `hooks/`, `settings.json`.
- `docs/` — bộ nhớ dự án: `ideas/` (chỉ đọc), `templates/`, `decisions/`, `reviews/`,
  `logs/` (transcript lần chạy lỗi), `learning-log.md`.
- `harness/gates/` — gate chạy ngoài session, trả exit code.
  `check_status.py`: nhánh có sửa file đã duyệt trên `master` không.
- `tests/` — `hooks/` và `gates/`. Sửa hook hay gate thì chạy lại test tương ứng
  trước khi commit.

## Sẽ thêm khi cần → ADR-0001 §C8, §C22
Điều kiện dưới đây là **dự kiến, xem lại đầu mỗi stage** — không phải luật cứng. Chúng
viết ở Stage 0, tức bằng thông tin cũ nhất mình từng có.

| Hạng mục | Điều kiện thêm |
|---|---|
| `architecture-review/` + vai Architecture | Khi `docs/intent.md` approved, bắt đầu Stage 2. |
| `security-review/` + vai Security | Khi Stage 2 chốt lưu dữ liệu người dùng ở đâu. |
| Vai Dev (Stage 3 + Stage 6) | Khi `docs/tasks.md` tồn tại. |
| Vai DevOps (Stage 5) | Khi có code chạy được và cần PR/CI thật. |
| Metric Maintain + ngưỡng mở `intent.md` mới | Khi Stage 5 deploy xong lần đầu. |
| `src/` | Khi `requirements.md` **và** `design.md` cùng approved, và test của task đó đã viết xong. |
| `harness/pipeline.yaml`, `harness/run.py` | Khi đã chạy tay trọn ≥1 vòng stage và các bước lặp đủ ổn định để script hóa. (`harness/gates/check_status.py` đã có từ round 3.) |
| `.github/workflows/gates.yml` | Khi `harness/gates/` đã có ít nhất một script chạy được ở local. |
| **Agent chạy trong container không có push token** | **Khi bắt đầu stage Dev.** Từ § "Mô hình mối đe dọa" (ADR-0001): ranh giới tin cậy thật là credentials, không phải hook. |

Thêm hạng mục nào thì ghi ADR kèm lý do.
