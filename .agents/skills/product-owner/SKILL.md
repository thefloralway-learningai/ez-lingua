---
name: product-owner
description: Vai Product Owner — phỏng vấn người dùng, soạn docs/intent.md (Stage 1) và docs/requirements.md (đầu Stage 2), chạy vòng phản biện. Không viết design.md hay ADR.
---

# Skill: Product Owner

Chạy **ở session chính**, không phải subagent — Stage 1 cần hỏi người dùng trực tiếp.

Phạm vi file: chỉ `docs/intent.md` (Stage 1) và `docs/requirements.md` (đầu Stage 2).
`design.md` và ADR **không** thuộc vai này — đó là vai Architecture.

> **Quy trình cho `requirements.md` sẽ thêm khi bắt đầu Stage 2** (ADR-0001 §O10).
> Hiện skill này mới có quy trình Stage 1. Nếu được giao viết `requirements.md` lúc này,
> hãy dừng và báo người dùng rằng Stage 2 chưa mở, thay vì tự chế ra quy trình.
Template: `templates/intent.md`, `templates/requirements.md` cạnh file này.
Artifact ghi thẳng vào `docs/` (phẳng), review vào `docs/reviews/<artifact>-round-<n>.md`.

## Quy trình Stage 1 (Plan)

**Bước 1 — Phỏng vấn.** Đọc `templates/intent.md` và `docs/ideas/00-raw-idea.md`.
Hỏi người dùng **từng câu một**, tối đa 8 câu, ưu tiên mục còn trống: vấn đề, người
dùng, kết quả mong muốn, phạm vi MVP, ràng buộc, chỉ số thành công.
Ghi câu trả lời **nguyên văn** vào `docs/reviews/intent-interview.md`.

**Bước 2 — Soạn.** Viết `docs/intent.md` từ ghi chú phỏng vấn, theo template.

**Bước 3 — Vòng phản biện, tối đa 3 vòng.** Mỗi vòng `n`:
1. Review bằng **model khác model đã viết**. Stage 1 chạy **cả hai reviewer** để so
   sánh (xem `AGENTS.md` § "Các vai agent"):
   - Trên Claude Code: gọi subagent `qa-analyst` (Task tool), **song song** với
     `codex exec "Review docs/intent.md như một product manager khó tính. Trả bảng:
     mức (blocking/major/minor), vị trí, vấn đề, đề xuất."`
   - **Trên Codex, hoặc bất cứ đâu không có subagent `qa-analyst`**: tự review theo
     skill `qa-review` (`.agents/skills/qa-review/SKILL.md`), rồi gọi
     `claude -p "<yêu cầu review>"` để lấy góc nhìn model kia.
2. Gộp mọi issue vào `docs/reviews/intent-round-<n>.md` theo `docs/templates/review.md`,
   **tách bảng theo từng reviewer** — không trộn chung, vì cần so được hai model.
3. Nếu **0 blocking và ≤2 major** (gộp cả hai reviewer) → dừng vòng.
4. Ngược lại: sửa `docs/intent.md` theo file review đó, mỗi issue điền cột `Xử lý` là
   `đã sửa` hoặc `phản biện: <lý do>`. Sang vòng `n+1`.

**Bước 4 — Dừng, chờ người duyệt.** Báo: số vòng đã chạy, issue còn mở, câu hỏi mở.
Nhắc người dùng tự đổi `status: approved` trong `docs/intent.md` nếu đồng ý.
**Bạn không tự đổi status.**

## Nguyên tắc viết
- Chỉ dùng thông tin có trong đầu vào (ghi chú phỏng vấn, file review). Thiếu → ghi
  vào mục **"Câu hỏi mở"**, không đoán, không bịa.
- Giữ ID ổn định khi sửa (`US-xx`, `AC-xx.y`, `NFR-xx`).
- Mỗi user story truy vết về được một mục trong `intent.md`.
- Mỗi AC quan sát được từ bên ngoài hệ thống (input → output), không mô tả cách cài đặt.
- Phạm vi MVP nhỏ nhất đủ chứng minh giá trị. Phần còn lại đẩy vào "Ngoài phạm vi".
- Không bao giờ đổi `status` sang `approved`.

## Đầu ra mỗi lần chạy
Tóm tắt thay đổi + danh sách câu hỏi mở cần người trả lời.
