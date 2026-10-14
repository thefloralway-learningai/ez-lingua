---
status: draft
date: 2026-10-14
---
# ADR-0001: Cấu trúc repo cho Giai đoạn 0

- Trạng thái: **draft** — chờ Codex review trước khi accept.

## Bối cảnh
Repo ở Stage 0: chưa có code, bước kế tiếp là Stage 1 (Plan). Bản draft cấu trúc
(`docs/ideas/01-repo-structure-draft.md`) đưa ra cấu trúc đầy đủ gồm cả `harness/`,
`.github/workflows/`, 4 skill và 2 subagent. Dựng toàn bộ ngay bây giờ sẽ tạo ra thư mục
rỗng mà Stage 1 không dùng tới, và khóa sớm những lựa chọn chưa được phản biện.
`reference/asdlc-starter/` có sẵn template, hook và settings đã chạy được.

## Các phương án
1. **Dựng đủ cấu trúc draft ngay** — khớp sơ đồ, nhưng phần lớn thư mục rỗng; harness và
   CI viết trước khi biết quy trình thật sự lặp ra sao.
2. **Chỉ dựng phần Stage 1 cần, kèm điều kiện mở rộng** — repo khớp giai đoạn thật; phải
   ghi lại điều kiện thêm để không quên.
3. **Clone nguyên `reference/asdlc-starter`** — nhanh nhất, nhưng kéo theo agent và
   command của Stage 2–3 chưa dùng tới, và starter chưa có quy tắc cross-model review.

→ Chọn **phương án 2**, tái sử dụng tài sản của starter.

## Quyết định — cấu trúc (§C1–§C13)

| § | Quyết định | Lý do |
|---|---|---|
| C1 | `AGENTS.md` là nguồn chung duy nhất; `CLAUDE.md` chỉ `@AGENTS.md` + phần riêng Claude Code | Claude và Codex cùng đọc một bản; tránh hai bản lệch nhau |
| C2 | Skill đặt ở `.agents/skills/`, `.claude/skills` là **symlink tương đối** `../.agents/skills` | Codex đọc trực tiếp `.agents/`; symlink tương đối vẫn đúng khi clone đi nơi khác |
| C3 | Subagent mỏng: chỉ `tools` + `skills` + vài dòng, kiến thức nằm trong skill | Sửa rubric ở một chỗ, cả hai công cụ cùng thấy |
| C4 | Chỉ tạo 2 skill (`product-owner`, `qa-review`) và 1 subagent (`qa-analyst`) | Đúng những gì Stage 1 cần |
| C5 | **Không tạo subagent `product-owner`**; vai PO chạy ở session chính | Stage 1 phải phỏng vấn người dùng; subagent không hỏi người dùng được |
| C6 | **Không tạo `.claude/commands/`**; quy trình Stage 1 nằm trong `product-owner/SKILL.md` | Slash command chỉ Claude Code dùng được; để trong skill thì Codex cũng chạy được cùng quy trình |
| C7 | Template intent/requirements đặt cạnh skill PO, không ở `docs/templates/` | Template là công cụ của vai PO; `docs/` để dành cho artifact thật |
| C8 | Hoãn `src/`, `harness/`, `.github/workflows/`, vai Architecture/Security/Dev/DevOps | Điều kiện thêm ghi trong AGENTS.md § "Sẽ thêm khi cần" |
| C9 | Hook `protect-approved.sh` chặn `Edit\|Write\|MultiEdit` lên file có `status: approved` | Biến "người duyệt" thành ràng buộc kỹ thuật, không chỉ là quy ước |
| C10 | Ý tưởng thô chép **nguyên văn** vào `docs/ideas/00-raw-idea.md`, không biên tập | Giữ một bản gốc bất biến để Stage 1 đối chiếu xem đã diễn giải lệch chưa |
| C11 | Tái sử dụng template, hook, settings, `.gitignore` từ `reference/asdlc-starter/`, không viết lại | Đã chạy được; viết lại chỉ sinh khác biệt vô nghĩa |

| C12 | **Vai Dev chạy trên Claude Code ở giai đoạn đầu**; Codex review code. Xem xét lại khi `harness/gates/` + CI đã chạy | Không phải vì Claude viết code tốt hơn — chưa đo. Lý do là hook, permission và subagent hiện chỉ có trong `.claude/`, nên chỉ ở đó mới ràng buộc được bằng máy quy tắc "test khóa trước khi viết code". Khi gate nằm ở `harness/` + CI thì ràng buộc không còn phụ thuộc công cụ, lúc đó chọn lại bằng dữ liệu |
| C13 | **Quy tắc truy vết**: mọi quyết định hoặc luật trong `AGENTS.md` phải trỏ tới nguồn (ADR hoặc file review). Mục chưa có nguồn mang dấu ⚠ và không được coi là đã chốt | Ở Stage 0 đã xảy ra một lần agent nâng một dòng liệt kê ngắn của người dùng thành dòng quyết định trong AGENTS.md, không hỏi lại và không ghi nguồn (xem `docs/learning-log.md`). Có nguồn thì đọc được ai quyết, lúc nào, vì sao — và phân biệt được "đã chốt" với "agent tự đề xuất" |

## Quyết định — quy trình (§P) — người dùng chốt 2026-10-14
Các điểm README nói nước đôi, nay đã chốt và đưa vào bảng 6 stage trong `AGENTS.md`:

| Stage | Chốt |
|---|---|
| Plan | Claude viết, Codex review |
| Design | **Claude** (README mục "Các bước" trước đây ghi Codex — đã sửa) |
| Dev | Test viết **trước** code rồi khóa. Ai viết code: xem §C12 (Claude Code ở giai đoạn đầu, có lý do riêng — không phải một phần của chốt ngày 2026-10-14) |
| Test | Codex (vai QA); kiểm thử tổng thể, không phải nơi viết unit test |
| Deploy | vai DevOps |
| Maintain | vai Dev; metric vượt ngưỡng → mở `intent.md` mới |

## Quyết định — xử lý 9 vấn đề còn mở (§O1–§O9) — người dùng chốt 2026-10-14

| § | Vấn đề | Quyết định | Lý do |
|---|---|---|---|
| O1 | README và AGENTS.md mô tả quy trình ở hai nơi, nội dung lệch nhau | README chỉ còn mô tả repo, câu hỏi nghiên cứu, cấu trúc, link sang AGENTS.md. Bảng agent, luồng phối hợp, "Các bước" chuyển hết sang AGENTS.md | Một nguồn duy nhất thì không thể lệch; hai nơi mô tả cùng một thứ chắc chắn sẽ trôi xa nhau |
| O2 | Chưa có vai cho Deploy và Maintain | Deploy → vai DevOps, Maintain → vai Dev. Cả hai vào mục "Sẽ thêm khi cần" kèm điều kiện | Có chủ sở hữu cho đủ 6 stage, nhưng không dựng vai khi chưa có code để deploy |
| O3 | QA Agent = Codex (README) vs subagent `qa-analyst` (Claude) — một vai hay hai? | **MỘT vai**, kiến thức ở skill `qa-review`. Người thực hiện = model khác bên viết. Stage 1 chạy cả hai reviewer, issue tách theo reviewer | Vai là kiến thức, không phải model. Tách issue theo reviewer để đo được câu hỏi nghiên cứu "hai model có bắt lỗi khác nhau không" |
| O4 | `product/giai-doan-0` thiếu đuôi `.md`, còn sót dòng `+++++` | Đổi thành `docs/ideas/01-repo-structure-draft.md`, xóa dòng `+++++`, xóa thư mục `product/` | Bản draft cũng là một ý tưởng đầu vào — thuộc `docs/ideas/`. Một thư mục `product/` chứa đúng một file là thừa |
| O5 | `00-raw-idea.md` chứa dòng tự trỏ về chính nó | Bỏ dòng đó, thêm "Nguồn: README.md, chuyển nguyên văn" | Dòng tự trỏ là điều hướng của README, không phải nội dung ý tưởng. Ghi nguồn giữ được truy vết mà không tự tham chiếu vòng |
| O6 | Artifact để `docs/` phẳng hay `docs/<stage>/`? | **Phẳng**. Chuyển sang `docs/<feature>/` khi có tính năng thứ hai | Một tính năng thì phân cấp chỉ thêm đường dẫn dài; chia theo feature hữu ích hơn chia theo stage |
| O7 | Tên file review theo stage hay theo artifact? | Theo artifact: `docs/reviews/<artifact>-round-<n>.md`, `<artifact>` ∈ `repo-structure`, `intent`, `requirements`, `design`, `tasks` | Một stage sinh nhiều artifact (Design sinh cả requirements lẫn design), tên theo stage sẽ đụng nhau |
| O8 | Ngưỡng dừng vòng review cho các stage sau | Mặc định 0 blocking, ≤2 major, tối đa 3 vòng. Gate riêng: `requirements` = QA đặt được tên test cho 100% AC; `design` = mọi AC có tầng test + mọi lựa chọn stack có ADR; `dev` = test/lint/SAST pass. Ghi rõ **"giá trị ban đầu, chỉnh theo learning-log"** | Cần một con số để bắt đầu đo, nhưng chưa có dữ liệu để biết nó đúng. Đánh dấu là tạm thời để sau này chỉnh mà không phải tranh luận lại |
| O9 | `reference/asdlc-starter/` có commit không? | Không commit, thêm `reference/` vào `.gitignore`, **xóa sau khi ADR-0001 được accept** | Chỉ là giàn giáo: đã rút xong template và hook. Giữ lại sẽ có người sửa nhầm bản copy |

## Mục chưa có nguồn — rà soát AGENTS.md ngày 2026-10-14
Theo §C13, các mục dưới đây đang nằm trong `AGENTS.md` nhưng **chưa có ADR hay file
review nào chống lưng**. Chúng mang dấu ⚠ trong AGENTS.md và **không được coi là đã
chốt**. Cần xử lý từng mục: hoặc người dùng chốt rồi ghi vào ADR, hoặc gỡ khỏi AGENTS.md.

| # | Mục trong AGENTS.md | Nó từ đâu ra | Xử lý đề xuất |
|---|---|---|---|
| U1 | Cột "Ai review" của Stage 6 (Maintain) để trống | Agent bỏ trống, không ai quyết là Maintain có cần review hay không | Chốt khi vai DevOps/Dev thành hình (Stage 5) |
| U2 | Sơ đồ "Luồng phối hợp" | Suy ra từ bảng 6 stage + sơ đồ cũ trong README; chưa ai duyệt riêng | Duyệt cùng lúc với bảng 6 stage, hoặc bỏ sơ đồ vì đã trùng bảng |
| U3 | "Điểm đặc thù của app học tiếng Anh" (3 gạch đầu dòng) | Giả định sản phẩm trong README gốc, chưa qua Stage 1 | Để Stage 1 xác nhận hoặc bác; sau đó chuyển vào `intent.md`, gỡ khỏi AGENTS.md |
| U4 | "Mọi artifact viết từ template, giữ nguyên ID" | Kế thừa từ `reference/asdlc-starter`, chép sang không hỏi | Chốt thành ADR-0002 hoặc ghi bổ sung vào ADR này |
| U5 | "Không bịa thông tin người dùng chưa nói" | Kế thừa từ `reference/asdlc-starter` | Như U4 |
| U6 | Quy tắc ngôn ngữ (tài liệu tiếng Việt, ID/code tiếng Anh) | Người dùng yêu cầu khi giao việc Stage 0, chưa ghi ADR | Ghi bổ sung vào ADR này khi accept |
| U7 | 8 dòng điều kiện trong bảng "Sẽ thêm khi cần" | Agent tự đề xuất ở Stage 0 | Người dùng duyệt từng dòng, hoặc để nguyên dạng "đề xuất, sửa được" |

Việc **hoãn** các hạng mục ở U7 thì đã có nguồn (§C8); chỉ *điều kiện cụ thể* là chưa.

## Hệ quả
- Repo nhỏ, mỗi file đang có người dùng. Đổi lại, mỗi lần sang stage mới phải quay lại
  mục "Sẽ thêm khi cần" và ghi thêm ADR.
- README không còn tự mô tả quy trình — ai muốn biết quy trình **phải** mở `AGENTS.md`.
- Symlink `.claude/skills`: môi trường không hỗ trợ symlink (một số checkout Windows) sẽ
  thấy skill rỗng.
- Các ngưỡng gate ở trên chưa có dữ liệu thực tế chống lưng; vòng chạy thật đầu tiên có
  thể cho thấy chúng quá chặt hoặc quá lỏng — lúc đó sửa ADR này, đừng lặng lẽ bỏ qua gate.
- Xóa `reference/` sau khi accept là **một chiều**: phải chắc đã rút hết thứ cần dùng.
- Quy tắc truy vết (§C13) hiện chỉ là **luật mềm**: không có gì chặn một agent ghi thêm
  dòng không nguồn vào AGENTS.md. Thành ràng buộc cứng khi `harness/gates/` có script
  kiểm mọi dòng quyết định đều trỏ tới một ADR tồn tại.

## Việc phải làm khi ADR này được accept
1. Xóa thư mục `reference/`.
2. Đổi `status: draft` → `status: accepted` ở đầu file này.
3. Ghi vào `docs/learning-log.md` điều rút ra từ vòng Stage 0.
4. Xử lý U1–U7 ở mục "Mục chưa có nguồn": chốt rồi ghi ADR, hoặc gỡ khỏi AGENTS.md.
