@AGENTS.md

## Riêng Claude Code

- **Skill**: `.claude/skills` là symlink tới `../.agents/skills`. Đừng chép skill vào
  `.claude/` — sửa bản gốc trong `.agents/skills/` để Codex đọc được cùng một nội dung.
- **Vai PO chạy ở session chính**, không phải subagent: Stage 1 cần hỏi người dùng
  trực tiếp mà subagent không làm được. Dùng skill `product-owner`.
- **Subagent**: chỉ reviewer mới là subagent. Hiện có `qa-analyst`
  (`.claude/agents/qa-analyst.md`, tools Read/Grep/Glob — chỉ đọc). Gọi nó qua Task tool
  sau mỗi lần artifact được viết hoặc sửa.
- **Reviewer khác model**: chạy song song `codex exec "<yêu cầu review>"` để có góc nhìn
  ngoài Claude, theo quy tắc "model nào viết thì model kia review" trong AGENTS.md.
- **Hook**: `PreToolUse` trên `Edit|Write|MultiEdit` chạy
  `.claude/hooks/protect-approved.sh`. File có `status: approved` → hook exit 2, chặn sửa.
  Nếu bị chặn: báo người dùng, đừng tìm cách lách bằng Bash.
- **Vai QA**: chỉ có một vai QA, kiến thức ở skill `qa-review`. Subagent `qa-analyst`
  là *người thực hiện* vai đó phía Claude. Khi chính Claude vừa viết artifact, reviewer
  chính phải là Codex — trừ Stage 1, nơi chạy cả hai để so sánh.
