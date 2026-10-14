---
name: qa-review
description: Rubric review tài liệu sản phẩm (intent.md, requirements.md) về khả năng kiểm thử, và định dạng bảng issue chuẩn. Dùng sau mỗi lần artifact được viết hoặc sửa.
---

# Skill: QA review

Bạn review, **không sửa file**. Đầu ra duy nhất là một bảng issue.

## Rubric cho `docs/intent.md`
| Kiểm | Không đạt → mức |
|---|---|
| Mỗi chỉ số thành công có **ngưỡng số** và **cách đo** cụ thể | blocking |
| "Trong phạm vi" và "Ngoài phạm vi" rõ ràng, không mâu thuẫn nhau | blocking |
| Vấn đề nêu được hiện người dùng đang xử lý thế nào, tốn gì | major |
| Ràng buộc về dữ liệu cá nhân / nơi lưu dữ liệu đã nêu | major |
| Giả định chưa kiểm chứng được ghi vào "Rủi ro và giả định" | minor |

## Rubric cho `docs/requirements.md` — áp cho TỪNG AC
1. **Viết được tên test cụ thể không?** Thử đặt tên, ví dụ
   `test_ac_01_1_tra_ve_dinh_nghia_theo_ngu_canh`.
   Không đặt được vì AC mơ hồ → **blocking**.
2. **Then có quan sát được từ ngoài hệ thống không?** Phải có số liệu hoặc điều kiện
   rõ. Các từ "nhanh", "chính xác", "thân thiện", "dễ dùng", "hợp lý" → **blocking**.
3. **Then mô tả kết quả, không mô tả cách cài đặt.** Nhắc tới bảng DB, hàm, framework
   → **major**.
4. **Trường hợp biên**: input rỗng, sai định dạng, không tìm thấy, quá lớn, trùng lặp.
   Thiếu → **major**.
5. **User story theo INVEST**: quá lớn, phụ thuộc chặt US khác, không ước lượng được
   → **major**.
6. **Truy vết**: mỗi US trỏ về được một mục trong `intent.md`. Không trỏ được → **major**.
7. **ID ổn định**: `US-xx`, `AC-xx.y`, `NFR-xx` không trùng, không nhảy cóc → **minor**.
8. **NFR có ngưỡng đo được** ở cột tương ứng. Trống → **major**.

## Định dạng bảng issue
Ghi ra `docs/reviews/<artifact>-round-<n>.md` (`<artifact>` ∈ `repo-structure`, `intent`,
`requirements`, `design`, `tasks` — đặt theo artifact, không theo stage):

```markdown
# Review <artifact> — vòng <n>

## Reviewer: qa-analyst
| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| 1 | blocking | AC-01.2 | Then ghi "trả về nhanh", không có ngưỡng | Đặt ngưỡng, ví dụ "dưới 2 giây" | |

## Reviewer: codex
| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|

Kết luận: còn <k> blocking, <m> major (gộp cả hai reviewer).
```

- **Mỗi reviewer một bảng riêng**, không trộn chung. Cần so sánh được hai model bắt
  những lỗi khác nhau thế nào — đây là một câu hỏi nghiên cứu của repo.
- Nếu hai reviewer nêu cùng một vấn đề, cứ để cả hai; phần trùng chính là dữ liệu.
- `Mức` chỉ nhận: `blocking` | `major` | `minor`.
- `Vị trí` là ID (`AC-01.2`, `US-03`, `NFR-01`) hoặc tên mục, không phải số dòng.
- Cột `Xử lý` để trống — người sửa điền `đã sửa` hoặc `phản biện: <lý do>`.

## Quy đổi mức độ giữa các reviewer
> **Giá trị ban đầu**, chỉnh theo `docs/learning-log.md` (ADR-0001 §O11).

Reviewer khác nhau dùng thang khác nhau: Codex trả `P0`–`P3` hoặc
`critical`/`high`/`medium`/`low`, repo này dùng `blocking`/`major`/`minor`. Quy đổi
**trước khi** gộp issue vào file review, nếu không thì ngưỡng dừng vô nghĩa:

| Reviewer nói | Repo ghi |
|---|---|
| `critical`, `high`, `P0`, `P1` | **blocking** |
| `medium`, `P2` | **major** |
| `low`, `P3` | **minor** |

Giữ nhãn gốc trong ngoặc để truy ngược: `blocking (codex: high)`. Nhờ vậy sau này kiểm
lại được quy đổi có quá nặng tay hay quá nhẹ tay không.

## Ngưỡng dừng
Mặc định: **0 blocking, ≤2 major, tối đa 3 vòng**. Với `requirements.md` thêm gate
cứng: đặt được tên test cụ thể cho **100% AC**. Đây là giá trị ban đầu — xem
`AGENTS.md` § "Ngưỡng dừng vòng review" và `docs/learning-log.md`.

## Kết thúc report
Sau bảng, liệt kê **tên test dự kiến** cho từng AC đã đạt yêu cầu. Đây là đầu vào cho
Stage 3, nơi test được viết trước code.
