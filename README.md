# learning-lingua
# Mô tả
Đây là repo dựng thử để học AISDLC, multiagent, subagent trong quá trình phát triển phần mềm. Repo này sẽ được cập nhật liên tục để cải thiện và hoàn thiện quy trình phát triển phần mềm tự động hóa.

# Ý tưởng app
Ý tưởng thô: docs/ideas/00-raw-idea.md
Xây dựng 1 app học tiếng anh đến từ fact để sử dụng tiếng anh trôi chảy 1 ngừoi lớn cần đọc hiểu các từ trong sách, sometimes ít xuất hiện khi đối thoại bình thường. Hay gặp vấn đề khi đọc sách tiếng anh là gặp từ mới, cần tra từ điển, sau không có công cụ ghi nhớ gì nên cũng dễ quên. App này là chỗ để người dùng điền từ mới vào, lookup với ngữ cảnh, app sẽ tạo ra bộ bài học riêng cho người dùng để học từ mới đó.
Ý tưởng này chưa sharp, vẫn cần PO agent brainstorm, phản biện, và chỉnh sửa để có được 1 ý tưởng rõ ràng hơn.

# Ý tưởng multi-agent

Ý tưởng multi-agent cho app học tiếng Anh này bao gồm các agent chuyên biệt phối hợp với nhau trong suốt vòng đời phát triển:

### Các Agent trong hệ thống

| Agent | Vai trò | Công cụ |
|---|---|---|
| **PO Agent** | Brainstorm, phản biện ý tưởng, viết intent & requirements | Claude, docs/intent.md |
| **Architecture Agent** | Thiết kế kiến trúc hệ thống, chọn tech stack | Claude, docs/design.md |
| **Dev Agent** | Sinh mã nguồn, implement feature | Codex, Read, Write |
| **QA Agent** | Viết test, kiểm tra AC coverage, báo cáo issue | Codex, harness/gates/ |
| **Security Agent** | Review bảo mật, kiểm tra dữ liệu người dùng | Claude, .agents/skills/security-review/ |

### Luồng phối hợp

```
PO Agent
  └─► viết docs/intent.md + docs/requirements.md
        └─► Architecture Agent thiết kế docs/design.md
              └─► Dev Agent sinh mã theo tasks.md
                    └─► QA Agent chạy test, ghi issue vào docs/reviews/
                          └─► Security Agent review dữ liệu từ vựng người dùng
                                └─► PO Agent duyệt kết quả, vòng lặp tiếp theo
```

### Điểm đặc thù của app học tiếng Anh

- **PO Agent** cần brainstorm kỹ: ai là người dùng, flow tra từ → tạo bài học → ôn tập như thế nào
- **QA Agent** kiểm tra: bộ flashcard sinh ra có đúng ngữ cảnh không, spaced repetition có hoạt động không
- **Security Agent** đảm bảo: từ vựng và ngữ cảnh người dùng nhập không bị lộ ra ngoài


## Giới thiệu
AISDLC là một quy trình phát triển phần mềm tự động hóa hoàn toàn từ đầu đến cuối, sử dụng các công cụ AI như Claude, Codex, và các công cụ khác để giảm thiểu sự can thiệp của con người 

Ý tưởng ứng dụng AISDLC xuyên suốt từ bước Plan -> design -> dev -> test -> deploy, sử dụng các công cụ như Claude, Codex, và các công cụ khác để tự động hóa quy trình phát triển phần mềm.

## Mục tiêu
- Tạo ra một quy trình phát triển phần mềm tự động hóa hoàn toàn từ đầu đến cuối.
- Sử dụng các công cụ AI để giảm thiểu sự can thiệp của con người trong quá trình phát triển.
- Tăng tốc độ phát triển phần mềm và giảm thiểu lỗi.

## Cấu trúc dự án
- `AGENTS.md`: Tài liệu về các agent và vai trò của chúng trong quy trình phát triển.
- `.agents/skills/`: Thư mục chứa các kỹ năng và kiến thức của các agent.
- `.claude/`: Thư mục chứa các cấu hình và cài đặt cho công cụ Claude.
- `harness/`: Thư mục chứa các công cụ và script để chạy và kiểm tra quy trình phát triển.
- `.github/workflows/gates.yml`: File cấu hình workflow cho GitHub Actions.
- `docs/`: Thư mục chứa các tài liệu và tài liệu liên quan đến dự án.

## Các bước thực hiện
1. **Plan**: Sử dụng công cụ Claude để tạo ra kế hoạch phát triển phần mềm.
2. **Design**: Sử dụng công cụ Codex để thiết kế kiến trúc và giao diện người dùng của phần mềm.
3. **Dev**: Sử dụng các công cụ AI để tự động hóa quá trình phát triển mã nguồn.
4. **Test**: Sử dụng các công cụ kiểm thử tự động để kiểm tra và đảm bảo chất lượng của phần mềm.
5. **Deploy**: Sử dụng các công cụ triển khai tự động để triển khai phần mềm lên môi trường sản xuất.
6. **Maintain**: Sử dụng các công cụ giám sát và phân tích để duy trì và cải thiện phần mềm.

## Kết quả mong đợi
- Tạo ra một quy trình phát triển phần mềm tự động hóa hoàn toàn từ đầu đến cuối.
- Giảm thiểu sự can thiệp của con người trong quá trình phát triển.
- Tăng tốc độ phát triển phần mềm và giảm thiểu lỗi.

## Tài liệu tham khảo
- [Claude](https://claude.ai/)
- [Codex](https://developers.openai.com/codex)
- [GitHub Actions](https://github.com/features/actions)
- [GitHub Skills](https://github.com/mattpocock/skills/tree/mai)
- [Github Skills](https://github.com/obra/superpowers)


