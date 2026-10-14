# Review repo-structure — vòng 2

Artifact: skeleton Stage 0 · diff `master...stage-0/skeleton` (23 file, +1070/−63).
Ngày: 2026-10-14. Vòng 2/3.
Mức đã quy đổi theo `.agents/skills/qa-review/SKILL.md`; nhãn gốc giữ trong ngoặc.

> **Mô hình mối đe dọa viết ra ở vòng này** (ADR-0001 § "Mô hình mối đe dọa"), sau khi
> hai vòng đầu xoay quanh hook mà không hội tụ. Hook = guardrail chống **nhầm lẫn**;
> cổng duyệt thật = **merge PR vào `master` do người làm**.
>
> Ranh giới xếp mức nằm ở chỗ **phải cố ý tới mức nào mới lọt**, không ở chỗ "có lọt hay
> không". Cả 5 finding vòng này đều lọt bằng **cách viết thông thường** — `status:
> "approved"` là YAML hợp lệ, `sed 's/draft/approved/'` là lệnh thường, Edit đổi mỗi giá
> trị là thao tác thường — nên đều là **blocking**: hook hỏng đúng việc nó nhận làm.
> Chỉ obfuscation có chủ đích (ghép chuỗi, base64) mới là **major**, và đó chính là
> `known_gap_bash_obfuscation` đang giữ nguyên. Lằn ranh này do người dùng duyệt ở vòng
> này → ADR-0001 §C23.

## Reviewer: codex-adversarial
`/codex:adversarial-review --base master` · session `01a13b1f-97f8-7680-99f2-74ff67405e64`
Verdict: **needs-attention** — *"the approval gate has two concrete fail-open paths,
including one reproduced in the review environment."*

| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| A1 | blocking (codex: high) | `protect-approved.sh:74` | `approves()` nhận input qua here-string, mà here-string cần **file tạm**. TMPDIR hỏng → shell báo `cannot create temp file for here document` → hàm trả "không khớp" → hook exit 0. Codex **tái hiện được** trong môi trường review. Hook fail open đúng lúc nó tuyên bố fail closed. | Bỏ here-string, truyền lỗi của scanner ra ngoài và chặn khi có lỗi. Thêm test với TMPDIR không ghi được. | **đã sửa** — viết lại bằng Python (`protect_approved.py`), không here-string, không file tạm. Mọi exception → exit 2. Test mới "TMPDIR khong ghi duoc: van chan" pass. |
| A2 | blocking (codex: high) | `protect-approved.sh:64-72` | Chỉ nhận đúng giá trị thường, không quote. `status: "approved"` hay `status: approved # ghi chú` đều là YAML hợp lệ cùng nghĩa nhưng lọt qua. Test cũ chỉ phủ cách viết chuẩn. | Parse frontmatter như YAML, hoặc chuẩn hóa quote và comment trước khi so sánh. Thêm test cho quote, comment, viết hoa, mọi trạng thái kết thúc. | **đã sửa** — `normalize()` bỏ comment (tôn trọng quote), bỏ quote, trim, lowercase. 5 test mới: quote, comment, viết hoa, cả ba cùng lúc, và ca ngược (`status: draft # chờ người dùng approved` → cho qua). |

## Reviewer: codex-review
`/codex:review --base master` · session `01a13b1f-0a4c-79c1-936d-d84ac28fd1f0`

| # | Mức | Vị trí | Vấn đề | Đề xuất | Xử lý |
|---|---|---|---|---|---|
| R1 | blocking (codex: P1) | `protect-approved.sh:30-32` | Edit/MultiEdit chỉ thay **giá trị**: `old_string="draft"`, `new_string="approved"`. `new_content` không chứa chữ `status:` nên `approves` trả false → tự duyệt trót lọt. | Dựng lại tài liệu sau khi áp thay đổi rồi mới kiểm. | **đã sửa** — hook đọc file hiện tại, áp `old_string`→`new_string` (và từng edit của MultiEdit, có tính `replace_all`), rồi kiểm **tài liệu kết quả**. 2 test mới cho Edit và MultiEdit chỉ đổi giá trị. |
| R2 | blocking (codex: P1) | `protect-approved-bash.sh:35-37` | `sed -i '' 's/draft/approved/' docs/intent.md` có chữ "approved" nhưng **không** có chữ "status", nên hook cũ cho qua. Đây là lệnh thường, không phải obfuscation đã biết. | Chặn cả thay đổi chỉ-giá-trị. | **đã sửa** — điều kiện mới: có một trạng thái kết thúc **và** (có chữ "status" **hoặc** có dấu hiệu ghi file: `sed -i`, `>>`, `tee`, `python`, heredoc…). Lệnh chỉ đọc (`grep approved docs/`) vẫn cho qua — có test cho cả hai chiều. |
| R3 | blocking (codex: P1) | `docs/templates/adr.md:2` | Mọi ADR tương lai phải dùng template này, nhưng template chỉ có dòng `- Trạng thái:` — hook chỉ nhận dạng dòng bắt đầu bằng `status:`. Một ADR dựng từ template có thể được accept rồi sửa tiếp mà **không hook nào chạm tới**. | Thêm frontmatter máy đọc được như ADR-0001. | **đã sửa** — template có `status: proposed` ở frontmatter, kèm comment giải thích vì sao không được bỏ và nhắc giữ khớp với dòng "Trạng thái". Xếp blocking vì đây không phải "vượt hook" mà là **hook không hề được gọi** — vùng không được bảo vệ. |

## Kết luận
**Phát hiện: 5 blocking** (A1, A2 từ `codex-adversarial`; R1, R2, R3 từ `codex-review`),
**0 major, 0 minor**. **Đã xử lý: 5/5.** Test hook: **36 pass, 0 fail, 1 known-gap**.

**Gate: chờ round 3.** Bên sửa không tự kết luận gate đạt — vòng review kế tiếp quyết
định (AGENTS.md § Quy tắc, ADR-0001 §C16). Đây là vòng 2/3.

Ngoài 5 finding trên còn **1 lỗi tự tìm khi viết test**, không reviewer nào nêu: thiếu
`python3` thì shebang trả exit 127, mà Claude Code chỉ coi exit 2 là chặn — fail open.
Chi tiết ở mục dưới.

## Thay đổi kiến trúc hook trong vòng này
`protect-approved.sh` và `protect-approved-bash.sh` giữ nguyên đường dẫn trong
`settings.json`, nhưng nay chỉ là **wrapper `sh` 10 dòng** gọi sang
`protect_approved.py` / `protect_approved_bash.py`.

Lý do cần wrapper thay vì để thẳng shebang `python3`: Claude Code chỉ coi **exit 2** là
chặn. Máy không có `python3` thì shebang thất bại và hook thoát **127** — tức *không*
chặn, đúng lúc cần chặn nhất. Wrapper kiểm `python3` trước và tự trả 2. Phát hiện khi
viết test, không reviewer nào nêu. Test: "Thieu python3: fail closed (exit 2, khong phai 127)".

## Lỗ hổng giữ nguyên, có chủ đích
`known_gap_bash_obfuscation` — lệnh ghép chuỗi `s=appro; echo "status: ${s}ved" >> f`
vẫn lọt. Không vá bằng khớp chuỗi được. Theo mô hình mối đe dọa, đây đúng là phần hook
**không nhận** nhiệm vụ chống. Biện pháp thật: container không có push token khi bắt
đầu stage Dev.
