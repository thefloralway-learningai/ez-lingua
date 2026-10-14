---
description: Stage 2 — từ intent đã duyệt tạo requirements.md và design.md, chạy vòng phản biện
---
Điều kiện: docs/intent.md phải có `status: approved`. Nếu không, dừng và báo người dùng.

Phần A — Requirements (tối đa 3 vòng):
1. Giao product-owner viết docs/requirements.md từ intent.md theo template.
2. Mỗi vòng: chạy song song qa-analyst và architect (review); chạy
   `codex exec "Review docs/requirements.md: AC nào mơ hồ, thiếu biên, mâu thuẫn với docs/intent.md?"`
   Gộp vào docs/reviews/requirements-round-<n>.md.
3. Gate thoát: 0 blocking VÀ qa-analyst đã đặt được tên test cho 100% AC.
4. Chưa đạt → product-owner sửa → vòng sau.

Phần B — Design (tối đa 3 vòng), chỉ làm khi Phần A đạt gate:
1. Giao architect viết docs/design.md và các ADR.
2. Mỗi vòng: chạy song song security-reviewer và qa-analyst (kiểm tra chiến lược test phủ đủ AC);
   chạy `codex exec "Review docs/design.md như staff engineer: over-engineering, rủi ro, điểm thiếu so với docs/requirements.md."`
   Gộp vào docs/reviews/design-round-<n>.md.
3. Gate thoát: 0 blocking, mọi AC có tầng test, mọi lựa chọn stack có ADR.

Kết thúc: báo kết quả cả hai phần, issue còn mở. Nhắc người dùng duyệt từng file. Không tự đổi status.
