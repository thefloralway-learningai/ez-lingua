# Review kiểm chứng — sau round 3

**Không phải round 4.** Ba vòng review theo ngưỡng dừng đã hết ở round 3; đây là lượt
chạy lại để kiểm chứng **bản sửa của round 3**, chủ yếu là code mới (`check_status.py`,
`harness/lib/`). Đánh số riêng để không nhầm với vòng phản biện.

Artifact: diff `master...stage-0/skeleton` (29 file, +1799/−63). Ngày: 2026-10-14.
Mức theo `.agents/skills/qa-review/SKILL.md`.

## Reviewer: codex-review
`/codex:review --base master` · session `01a13b38-290f-7ed0-9171-481a47064b6c`

| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| V1 | blocking (codex: P1) | `check_status.py:95-98` | File đã duyệt bị **đổi tên** thì `git diff --name-only` chỉ báo đường đích; `git show base:<đích>` thất bại và `continue` coi nó như file mới. Một `git mv docs/intent.md docs/renamed.md` thường đi qua gate. | Dùng output nhận biết rename, soi đường nguồn ở merge-base. | **đã sửa** — `git diff --name-status --no-renames`, chỉ xét path có mã `M` hoặc `D`. `--no-renames` làm một lần đổi tên hiện thành `D` (đường cũ) + `A` (đường mới), nên bị bắt ở nhánh `D`. Test `git mv file da approved` → exit 1. |
| V2 | blocking (codex: P1) | `check_status.py:67-70` | Gate đòi đúng tiền tố `status:` nên bỏ sót `status : approved` — YAML hợp lệ, và **hook thì nhận**. Hai parser lệch nhau; mọi sửa đổi về sau lên artifact đó đều qua gate. | Dùng lại parser của hook, hoặc khớp chịu được khoảng trắng. | **đã sửa** — tách `harness/lib/frontmatter.py` làm **parser duy nhất**; hook và gate cùng import, hai bản cũ xóa hết. Test `status : approved` → exit 1. |
| V3 | blocking (codex: P1) | `protect_approved_bash.py:69-74` | Trạng thái kết thúc khớp như chuỗi con bất kỳ, và mọi lệnh python/node/ruby bị coi là ghi → `python3 -m py_compile .claude/hooks/protect_approved.py` bị chặn chỉ vì **tên file** chứa chữ "approved". Lệnh này không thay bằng Read được. Theo chính skill QA, chặn nhầm việc vô hại là blocking. | Thu hẹp nhận dạng, hoặc đừng coi mọi lệnh interpreter là ghi. | **đã xử lý — bằng cách xóa hook Bash**, không bằng cách thu hẹp. Ghi qua Bash đã nằm ngoài phạm vi hook từ round 3 và được `check_status.py` bắt; giữ thêm một lớp chỉ sinh false positive. Xóa `protect_approved_bash.py`, mục `matcher: Bash` trong settings.json, và test của nó. |
| V4 | minor (codex: P3) | `README.md:49-50` | Cùng một thay đổi vừa thêm `harness/gates/check_status.py` vừa nói `harness/` chưa có. | Chỉ liệt kê phần harness còn hoãn. | **đã sửa** — README liệt kê `harness/` trong cây thư mục, thêm dòng chạy gate trước khi mở PR, và mục "chưa có" nay chỉ còn `src/`, `harness/pipeline.yaml`, `harness/run.py`, `.github/workflows/`. |

## Kết luận
**Phát hiện: 3 blocking, 0 major, 1 minor. Đã xử lý: 4/4.**
Test: hook **32 pass, 0 fail, 1 known-gap** · gate **16 pass, 0 fail, 1 known-gap**.
`python3 harness/gates/check_status.py` trên nhánh này: **exit 0**.

Không kết luận gate đạt — bên sửa không có quyền đó (§C16).

## Nhận xét về chính vòng này
Ba finding blocking đều nằm ở **code mới của round 3** (`check_status.py` vừa viết,
hook Bash vừa thu hẹp phạm vi), không phải ở cùng một lớp bị đuổi suốt ba vòng trước.
Đó là dấu hiệu khác hẳn: lỗi ở code mới là bình thường và hữu hạn, còn ba vòng trước là
*không hội tụ trên cùng một lớp* — vá chỗ này hở chỗ kia. Chuyển việc sang gate đã dừng
được kiểu thứ hai.
