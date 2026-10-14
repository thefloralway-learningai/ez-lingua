# learning-lingua

## Mô tả
Repo dựng thử để học AI-native SDLC: multi-agent, subagent, skill, hook trong quá trình
phát triển phần mềm. Repo được cập nhật liên tục để cải thiện và hoàn thiện quy trình
phát triển phần mềm tự động hóa.

Sản phẩm đích là một app học tiếng Anh từ vựng theo ngữ cảnh. Ý tưởng thô:
[`docs/ideas/00-raw-idea.md`](docs/ideas/00-raw-idea.md) — chưa sharp, còn chờ PO agent
brainstorm và phản biện ở Stage 1.

**Trạng thái: Stage 0 xong — chưa có code.**

## Câu hỏi nghiên cứu
Repo này tồn tại để trả lời mấy câu, không phải để ship app nhanh:

1. Một quy trình phát triển chạy chủ yếu bằng agent, từ Plan tới Maintain, cần bao
   nhiêu điểm can thiệp của con người thì vẫn giữ được chất lượng?
2. **Có tăng tốc thật không?** Đo bằng *lead time*: số giờ từ lúc `docs/intent.md`
   được approved tới lúc PR đầu tiên của tính năng đó merged.
3. **Có giảm lỗi thật không?** Đo bằng *tỷ lệ rework*: (a) số vòng review cần để một
   artifact đạt ngưỡng dừng, (b) tỷ lệ AC phải viết lại **sau khi** đã approved,
   (c) số defect lọt tới Stage 4 (Test) mà Stage 3 lẽ ra phải bắt được.
4. Dùng hai model khác nhau (Claude và Codex) để bên này viết bên kia review có bắt
   được lỗi mà một model tự review bỏ sót không?
5. Kiến thức vai trò nên nằm ở đâu để cả Claude lẫn Codex dùng chung được, thay vì mỗi
   công cụ một bản?
6. Gate nào nên là ràng buộc kỹ thuật (hook, CI) thay vì chỉ là quy ước trong tài liệu?

Câu 2 và 3 chỉ đo được từ vòng tính năng đầu tiên trở đi; trước đó ghi "chưa có dữ liệu".

Điều rút ra ghi vào [`docs/learning-log.md`](docs/learning-log.md).

## Quy trình và agent
**Nguồn duy nhất là [`AGENTS.md`](AGENTS.md)** — 6 stage, artifact của từng stage, ai
viết, ai review, và các quy tắc chung. Đừng mô tả lại quy trình ở file này để tránh hai
bản lệch nhau.

[`CLAUDE.md`](CLAUDE.md) chỉ trỏ về `AGENTS.md` cộng vài dòng riêng cho Claude Code.

## Cấu trúc dự án
```
AGENTS.md            nguồn chung: quy trình, agent, quy tắc
CLAUDE.md            @AGENTS.md + phần riêng Claude Code
.agents/skills/      kiến thức vai trò, dùng chung cho Claude và Codex
.claude/             riêng Claude Code: skills (symlink), agents, hooks, settings
harness/             lib/frontmatter.py + gates/check_status.py (chạy ngoài session)
docs/                bộ nhớ dự án: ideas, templates, decisions, reviews, learning-log
tests/               test cho hook và gate
```
Chạy `python3 harness/gates/check_status.py` trước khi mở PR.

Chưa có và điều kiện để thêm (xem `AGENTS.md` § "Sẽ thêm khi cần"): `src/`,
`harness/pipeline.yaml`, `harness/run.py`, `.github/workflows/`.

## Tài liệu tham khảo
- [Claude](https://claude.ai/)
- [Codex](https://developers.openai.com/codex)
- [GitHub Actions](https://github.com/features/actions)
- [GitHub Skills](https://github.com/mattpocock/skills/tree/mai)
- [Github Skills](https://github.com/obra/superpowers)
