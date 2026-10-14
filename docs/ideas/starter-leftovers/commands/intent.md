---
description: Stage 1 — phỏng vấn ý tưởng, tạo docs/intent.md, chạy vòng phản biện
argument-hint: <mô tả ý tưởng 1-2 câu>
---
Ý tưởng ban đầu: $ARGUMENTS

Bước 1 — Phỏng vấn (bạn làm, vì subagent không hỏi người dùng được):
Đọc docs/templates/intent.md. Hỏi người dùng TỪNG CÂU MỘT, tối đa 8 câu, ưu tiên mục còn trống:
vấn đề, người dùng, kết quả mong muốn, phạm vi MVP, ràng buộc, chỉ số thành công.
Ghi chú câu trả lời nguyên văn vào docs/reviews/intent-interview.md.

Bước 2 — Soạn: giao subagent product-owner viết docs/intent.md từ ghi chú phỏng vấn.

Bước 3 — Vòng phản biện, tối đa 3 vòng. Mỗi vòng n:
  a. Chạy SONG SONG subagent qa-analyst và architect (chế độ review) trên docs/intent.md.
  b. Chạy reviewer khác model:
     `codex exec "Review docs/intent.md như một product manager khó tính. Trả bảng: mức (blocking/major/minor), vị trí, vấn đề, đề xuất."`
  c. Gộp tất cả issue vào docs/reviews/intent-round-<n>.md theo template review.md.
  d. Nếu 0 blocking và ≤2 major → dừng vòng.
  e. Ngược lại, giao product-owner sửa theo file review đó, rồi sang vòng n+1.

Bước 4 — Dừng và báo người dùng: số vòng đã chạy, issue còn mở, câu hỏi mở.
Nhắc người dùng: đổi `status: approved` trong docs/intent.md nếu đồng ý. Bạn không tự đổi.
