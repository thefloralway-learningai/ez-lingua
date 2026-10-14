# Giai đoạn 0: dựng style anchor
# Ý tưởng cấu trúc draft repo, vẫn cần architect-agent phản biện đưa ra kết quả cuối 


repo/
├── AGENTS.md                  ← NGUỒN CHUNG: dự án, quy trình, lệnh build/test, quy tắc
├── CLAUDE.md                  ← chỉ gồm "@AGENTS.md" + vài dòng riêng cho Claude
│
├── .agents/skills/            ← NGUỒN CHUNG cho kiến thức vai trò (Codex đọc trực tiếp)
│   ├── product-owner/
│   │   ├── SKILL.md
│   │   ├── templates/  intent.md, requirements.md
│   │   └── agents/openai.yaml     ← tên hiển thị trên Codex (tùy chọn)
│   ├── qa-review/SKILL.md          ← rubric kiểm AC, định dạng bảng issue
│   ├── architecture-review/SKILL.md
│   └── security-review/SKILL.md
│
├── .claude/                   ← RIÊNG CLAUDE CODE: cách chạy và luật lệ
│   ├── skills → ../.agents/skills  ← symlink, không chép lại
│   ├── agents/                     ← subagent mỏng: chỉ tools + skills, không chứa kiến thức
│   │   ├── qa-analyst.md           (tools: Read,Grep,Glob · skills: [qa-review])
│   │   └── security-reviewer.md    (skills: [security-review])
│   ├── hooks/protect-approved.sh
│   └── settings.json               ← permission + hook
│
├── harness/                   ← LỚP THICK (thêm sau khi chạy thử)
│   ├── pipeline.yaml               ← các stage, gate, số vòng tối đa
│   ├── run.py                      ← gọi `claude -p` và `codex exec`, chạy vòng lặp
│   └── gates/                      ← script kiểm tra trả exit code
│       ├── check_status.py         (file đã approved chưa)
│       ├── check_ac_coverage.py    (mọi AC có test chưa)
│       └── check_review.py         (còn issue blocking không)
│
├── .github/workflows/gates.yml ← CI chạy lại đúng các script trong harness/gates/
│
└── docs/                      ← ARTIFACT: bộ nhớ của dự án, mọi agent đọc chung
    ├── intent.md  requirements.md  design.md  tasks.md
    ├── reviews/   decisions/