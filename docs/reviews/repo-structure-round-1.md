# Review repo-structure — vòng 1

Artifact: skeleton Stage 0 · diff `master...stage-0/skeleton` (20 file, +611/−63).
Ngày: 2026-10-14.
Mức độ đã quy đổi theo bảng trong `AGENTS.md` § "Quy đổi mức độ issue giữa các reviewer";
nhãn gốc của reviewer giữ trong ngoặc.

> Vòng 0 không tồn tại: hai lần gọi Codex đầu tiên chết vì mất mạng và 404 model, lại
> chạy sai target (đứng trên `master` nên `master...HEAD` rỗng). Transcript lưu ở
> `docs/logs/codex-run-failures.md`, không phải ở đây.

## Reviewer: codex-adversarial
`/codex:adversarial-review --base master` · session `01a13ade-2aee-7a81-9c33-4c098776e0d7`
Verdict: **needs-attention** — *"Do not ship: the approval gate can be satisfied by the
agent it is supposed to constrain."*

| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| 1 | blocking (codex: high) | `.claude/hooks/protect-approved.sh:9-11` | Hook chỉ đọc nội dung **hiện tại** của file. Một Edit/Write đổi `status: draft` → `approved` vẫn lọt; sau đó file bị khóa và quy trình tưởng người dùng đã duyệt. Agent tự duyệt được sản phẩm của chính nó. Codex thử payload Edit lên ADR draft và nhận exit 0. | Đọc cả nội dung sắp ghi trong `tool_input`; thêm test tự động cho draft→approved, overwrite, file đã approved. | **đã sửa** — hook đọc `.content` / `.new_string` / `.edits[].new_string`; thêm `protect-approved-bash.sh` chặn đường vòng shell; cả hai fail closed; `tests/hooks/test_protect_approved.sh` 27 case pass. Đúng payload Codex mô tả nay trả exit 2. ADR-0001 §C14. |

## Reviewer: codex-review
`/codex:review --base master` · session `01a13acf-07f5-7172-8802-943448b9c4ef`

| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| 2 | major (codex: P2) | `.claude/hooks/protect-approved.sh:11` | ADR dùng `status: accepted` làm trạng thái cuối, nhưng hook chỉ khớp `approved` → ADR đã accepted vẫn sửa được, trái với luật bảo vệ artifact đã duyệt trong AGENTS.md. | Thống nhất một từ, hoặc chặn cả hai giá trị. | **đã sửa** — giữ hai bộ từ vựng (artifact `draft`→`approved`, ADR `proposed`→`accepted`/`superseded`) và cho hook chặn **mọi trạng thái kết thúc**: `approved`, `accepted`, `superseded`. Thêm 7 case test (ADR proposed→accepted qua Edit/Write, sửa ADR đã accepted, đặt `superseded`, và các case cho qua). |
| 3 | major (codex: P2) | `AGENTS.md` vs `.agents/skills/product-owner/SKILL.md` | Bảng 6 stage giao `requirements.md` cho vai Architecture, trong khi skill PO ghi `requirements.md` trong phạm vi của mình — mà quy trình trong skill chỉ tạo `intent.md`. Một yêu cầu "viết requirements" có thể bị định tuyến tới skill không bao giờ sinh ra artifact đó. | Chốt một chủ sở hữu và bổ sung bước tạo nó. | **đã sửa** — `requirements.md` thuộc **vai Product Owner**, tạo ở **đầu Stage 2**; `design.md` + ADR thuộc **vai Architecture**. Sửa cả bảng 6 stage lẫn bảng vai trong AGENTS.md, và phạm vi trong SKILL.md. Quy trình requirements trong skill PO **sẽ thêm khi bắt đầu Stage 2** — ghi rõ ở cả hai nơi. ADR-0001 §O10. |
| 4 | minor (codex: P2) | `docs/reviews/repo-structure-round-0.md:24-27` | File review chuẩn của vòng 0 chỉ chứa transcript CLI lỗi, không có bảng reviewer, số đếm mức độ hay kết luận → cổng review không xác định được Stage 0 có pass hay không. Vi phạm định dạng per-reviewer bắt buộc. | Chạy lại review vào đúng template, hoặc đưa transcript lỗi ra ngoài vùng tên chuẩn. | **đã sửa** — chuyển thành `docs/logs/codex-run-failures.md` kèm ghi chú nguyên nhân (404 model `gpt-6-sol` + mất mạng + sai target), và nói rõ "đây không phải một review". File này là review thật của vòng 1. |

Kết luận: còn **0 blocking, 0 major, 0 minor**. Tất cả 4 issue đã xử lý.

## Phát sinh ngoài review
Khi viết test cho issue #1, phát hiện thêm một lỗi không reviewer nào nêu: hook
**fail open** — thiếu `jq`/`python3` hoặc JSON hỏng thì trả exit 0, tức cho qua. Một cổng
duyệt hỏng mà mở thì vô dụng. Đã đổi cả hai hook sang **fail closed**, thêm 7 case phủ
nhánh suy biến. Ghi vào `docs/learning-log.md`.

Một case test **cố tình khẳng định một lỗ vẫn còn**: lệnh Bash ghép chuỗi
`s=appro; echo "status: ${s}ved" >> f` vẫn lọt. Giữ lại để không ai đọc "27/27 pass" rồi
tưởng hook là ranh giới kín. Hook là best-effort; cổng duyệt thật là con người
(ADR-0001 § "Cổng duyệt thật — quyết định cần người").
