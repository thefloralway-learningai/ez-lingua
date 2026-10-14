# Review repo-structure — vòng 3

Artifact: skeleton Stage 0 · diff `master...stage-0/skeleton` (26 file, +1381/−63).
Ngày: 2026-10-14. **Vòng 3/3 — hết số vòng.**
Mức theo `.agents/skills/qa-review/SKILL.md`; nhãn gốc giữ trong ngoặc.

Focus do người dùng đặt: hook có bắt được lỗi agent **vô tình** gây ra không · mô hình
mối đe dọa và rủi ro còn lại có ghi trung thực không · còn mâu thuẫn giữa AGENTS.md,
skill và ADR không.

## Reviewer: codex-adversarial
`/codex:adversarial-review --base master` + focus text · session `01a13b31-0c8f-73d1-a5c4-854c5403a7e2`
Verdict: **needs-attention**

| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| 1 | blocking (codex: high) | `protect_approved_bash.py:55-64` | Hook chỉ tìm chuỗi trạng thái trong **câu lệnh**, không đọc trạng thái **file đích**. `sed -i 's/old/new/' docs/intent.md` trả exit 0 → sửa được nội dung một `intent.md` đã `approved`. Lệnh shell bình thường, không phải obfuscation. | Chặn mọi lệnh có thể ghi vào artifact, hoặc xác định file đích rồi kiểm trạng thái. Thêm test cho `git restore`/`git checkout`. | **đã xử lý — bằng cách thu hẹp phạm vi, không bằng cách vá tiếp.** Người quyết ở vòng này: ghi qua Bash **nằm ngoài phạm vi hook**, chuyển cho `harness/gates/check_status.py` (gate chạy trên git, ngoài session). `protect_approved_bash.py` hạ xuống mức "nhắc nhở best-effort", ghi rõ trong comment đầu file. ADR-0001 § "Phạm vi từng lớp". |
| 2 | blocking (codex: high) | `AGENTS.md:75-81` | AGENTS.md ghi "mọi finding vượt được hook là major", trong khi §C23 và skill QA ghi "lọt bằng cách viết thông thường là blocking". Reviewer theo AGENTS.md sẽ hạ finding #1 xuống major; gate cho phép ≤2 major nên thay đổi lọt qua dù guardrail hỏng. | Thay câu tổng quát bằng đúng lằn ranh §C23; đồng bộ ADR dòng 117–121. | **đã sửa** — người quyết: **xóa mọi diễn giải quy đổi** khỏi AGENTS.md và ADR. Hai nơi đó giờ chỉ còn một dòng trỏ sang `.agents/skills/qa-review/SKILL.md`, là **nguồn duy nhất**. §O11 và §C23 cũng không còn chép bảng. |
| 3 | blocking (codex: high) | `protect_approved.py:27-72` | Regex quét **toàn bộ** nội dung. Một tài liệu có frontmatter `status: draft` nhưng chứa code fence minh họa `status: approved` bị Write chặn (xác nhận exit 2), rồi mọi lần sửa sau cũng bị coi là sửa file đã chốt. False positive — theo §C23 là blocking, vì nó đẩy người ta sang Bash hoặc tắt guardrail. | Chỉ phân tích `status` trong YAML frontmatter đầu file. Thêm test cho code fence và văn xuôi. | **đã sửa** — `frontmatter()` chỉ đọc khối giữa hai dòng `---` ở **đầu** file; ngoài khối đó bỏ qua hoàn toàn. Không có frontmatter → không phải artifact được quản lý → cho qua. Frontmatter mở mà không đóng → exit 2. 5 test mới: code fence, văn xuôi, không frontmatter, frontmatter hỏng (nội dung sắp ghi và file hiện tại). |

## Kết luận
**Phát hiện: 3 blocking, 0 major, 0 minor.** **Đã xử lý: 3/3.**
Test: hook **41 pass, 0 fail, 1 known-gap** · gate **11 pass, 0 fail, 1 known-gap**.

**Hết 3 vòng review, không hội tụ bằng cách vá tiếp.** Theo ngưỡng dừng
(tối đa 3 vòng), người dùng quyết hướng xử lý — xem ADR-0001 § "Phạm vi từng lớp"
và § "Mô hình mối đe dọa". Thay đổi lớn nhất của vòng này không phải một bản vá mà là
**chuyển việc canh "ghi qua Bash" từ hook (trong session) sang gate git (ngoài session)**.

Không kết luận gate đạt — bên sửa không có quyền đó (§C16).

## Gate thick đầu tiên
`harness/gates/check_status.py`: so `master...HEAD`, file nào trên `master` có
frontmatter status ∈ {approved, accepted, superseded} mà nhánh này sửa → FAIL, in tên
file. Chạy trước khi mở PR.

**Known-gap**: commit do **chính người dùng** đổi status cũng bị báo FAIL — gate không
phân biệt được người duyệt với agent, vì dùng chung credentials git. Người kiểm bằng
mắt khi duyệt PR. Gỡ được khi agent chạy bằng credentials riêng.
