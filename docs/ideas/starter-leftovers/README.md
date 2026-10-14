# Phần còn lại của `reference/asdlc-starter`

**Đây không phải cấu hình đang chạy.** Chỉ là tài liệu để đọc khi tới Stage 2–3.
Không có file nào ở đây được Claude Code hay Codex nạp: skill nằm ở `.agents/skills/`,
subagent nằm ở `.claude/agents/`, template đang dùng nằm ở `docs/templates/`.

## Vì sao có thư mục này
ADR-0001 §O9 chốt xóa `reference/asdlc-starter/` sau khi ADR được accept. Lúc sắp xóa
thì thấy 7 file **chưa từng được rút ra**, toàn thứ Stage 2–3 sẽ cần — mà thư mục gốc
chưa bao giờ được commit (gitignored), nên xóa là mất hẳn. Rút chúng ra đây rồi mới xóa.

Giữ ở `docs/ideas/` vì đúng bản chất: **đầu vào chưa qua phản biện**, giống
`00-raw-idea.md` và `01-repo-structure-draft.md`. Không phạm §C8 (hoãn tạo vai
Architecture/Security/Dev) vì không có gì ở đây đang hoạt động.

## Có gì
| File | Dùng khi | Lưu ý |
|---|---|---|
| `design.md` | Stage 2 — template cho `docs/design.md` | Chưa qua rubric `qa-review`; gate design yêu cầu "mọi AC có tầng test, mọi lựa chọn stack có ADR" mà template này chưa có mục nào cho hai thứ đó |
| `agents/architect.md` | Stage 2 — vai Architecture | Subagent **dày** (kiến thức nằm trong file agent). Trái §C3: repo này dùng subagent mỏng + skill. Phải tách kiến thức sang `.agents/skills/architecture-review/` trước khi dùng |
| `agents/security-reviewer.md` | Stage 2 — vai Security | Như trên |
| `agents/verifier.md` | Stage 3–4 | Vai này repo chưa định nghĩa; bảng 6 stage không có "verifier" |
| `commands/intent.md` | Stage 1 | Quy trình đã chuyển vào `.agents/skills/product-owner/SKILL.md` (§C6). Giữ để đối chiếu, **đừng tạo lại `.claude/commands/`** |
| `commands/spec.md` | Stage 2 | Chưa có bản tương đương trong skill — đây là tài liệu tham khảo chính khi viết quy trình requirements/design |
| `commands/tasks.md` | Stage 3 | Như trên |

## Khi dùng tới
Rút nội dung sang skill/template thật rồi **xóa file tương ứng ở đây**. Khi thư mục này
rỗng thì xóa luôn — nó là giàn giáo, không phải tài sản.
