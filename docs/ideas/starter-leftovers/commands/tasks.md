---
description: Chia requirements + design đã duyệt thành task cho Stage 3
---
Điều kiện: docs/requirements.md và docs/design.md đều `status: approved`.

Dùng plan mode. Viết docs/tasks.md:
- Mỗi task: ID (T-01...), mô tả, các AC nó hoàn thành, file/module dự kiến đụng tới, phụ thuộc.
- Task đầu tiên luôn là T-00: dựng khung repo (cấu trúc thư mục, công cụ test, lint, CI rỗng).
- Mỗi task đủ nhỏ để một PR review được trong khoảng 15 phút.
- Đánh dấu nhóm task chạy song song được (không đụng chung file) để chạy trên worktree riêng.
Sau đó chạy `codex exec "Review docs/tasks.md: task nào quá lớn, phụ thuộc sai, hoặc thiếu AC?"` và sửa.
