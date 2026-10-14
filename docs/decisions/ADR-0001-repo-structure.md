---
status: proposed
date: 2026-10-14
---
# ADR-0001: Cấu trúc repo cho Giai đoạn 0

- Trạng thái: **proposed** — chờ review hội tụ rồi người dùng accept.
  (Dùng từ vựng ADR `proposed → accepted/superseded`, khớp `docs/templates/adr.md`.)

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

## Quyết định — cấu trúc (§C1–§C23)

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

| C14 | **Hook chỉ là lớp best-effort, không phải ranh giới bảo mật.** `protect-approved.sh` đọc cả nội dung sắp ghi trong `tool_input` (Write `.content`, Edit `.new_string`, MultiEdit `.edits[].new_string`) và chặn mọi thao tác của agent đưa status về một **trạng thái kết thúc** — `approved` (artifact), `accepted`/`superseded` (ADR); `protect-approved-bash.sh` chặn best-effort lệnh shell chứa "status" cùng một trạng thái kết thúc. Cả hai **fail closed**. Cổng duyệt thật: xem mục "Cổng duyệt thật — quyết định cần người" | Codex adversarial review (`repo-structure-round-1.md` #1) chứng minh hook cũ chỉ đọc nội dung *hiện tại* của file, nên một Edit `draft` → `approved` vẫn lọt — agent tự duyệt được sản phẩm của chính nó rồi khóa file lại. Vá xong thì đường vòng vẫn còn (ghép chuỗi, base64, viết script rồi chạy), nên không được coi hook là ranh giới tin cậy: nó chỉ biến việc lách luật thành hành vi phải cố ý |

| C15 | **Việc tự quyết ngoài yêu cầu phải liệt kê ở cuối báo cáo**, mỗi việc một dòng kèm lý do, không gộp vào phần "đã làm" | Agent luôn phải tự quyết vài thứ nhỏ để đi tiếp; vấn đề không nằm ở chỗ nó tự quyết mà ở chỗ quyết định đó lẫn vào phần việc được giao, khiến người dùng không biết chỗ nào cần kiểm. Đây là cùng một gốc với §C13 (truy vết): phân biệt "đã chốt" với "agent tự chọn". Liệt kê riêng thì bác bỏ chỉ tốn một câu |

| C16 | **Bên sửa không kết luận gate đạt**; chỉ ghi "đã xử lý n/n" và "Gate: chờ round n+1". Vòng review kế tiếp quyết định | Ở vòng 2 agent tự ghi "còn 0 blocking, 0 major" ngay trong file review của chính vòng đó — tức vừa sửa vừa tuyên bố mình đã sửa xong. Bên vừa sửa là bên ít có khả năng thấy chỗ mình sửa hụt nhất; và nếu bên sửa tuyên bố được gate thì gate không còn là gate (cùng một lỗi hình thức với §C14: ai bị ràng buộc thì không được cầm chìa khóa) |

| C17 | *(U1)* **Stage 6 (Maintain) không có vòng review riêng.** Metric vượt ngưỡng → mở `intent.md` mới, chạy lại từ Stage 1. **Tạm thời — xem lại khi tới Stage 6** | Review có nghĩa khi có artifact mới để soi. Maintain không sinh artifact, nó sinh *tín hiệu*; phản ứng đúng với tín hiệu là mở lại vòng đời chứ không phải review tại chỗ. Đánh dấu tạm thời vì đây là suy luận trên giấy, chưa vận hành ngày nào |
| C18 | *(U3)* **Xóa "Điểm đặc thù của app học tiếng Anh" khỏi `AGENTS.md`.** Nội dung gốc giữ nguyên ở `docs/ideas/00-raw-idea.md` | `AGENTS.md` nạp vào **mọi session**, nên mọi giả định sản phẩm nằm trong đó sẽ định hướng PO agent **trước khi** Stage 1 kịp hỏi người dùng câu nào. Đó đúng là thứ Stage 1 phải tự tìm ra, không phải thứ được mớm sẵn |
| C19 | *(U4)* **Artifact viết từ template; ID (`US-xx`, `AC-xx.y`, `NFR-xx`) giữ ổn định khi sửa** | ID là thứ review và test trỏ tới. Đổi ID làm đứt mọi tham chiếu: review vòng `n` nói `AC-01.2`, vòng `n+1` đánh số lại, hai file không còn khớp và không ai phát hiện ra |
| C20 | *(U5)* **Không bịa thông tin người dùng chưa nói; thiếu thì ghi vào "Câu hỏi mở"** | Một giả định bịa trông y hệt một sự thật khi đọc lại sau ba tuần. Bắt nó hiện ra thành câu hỏi là cách duy nhất giữ được phân biệt đó |
| C21 | *(U6)* **Tài liệu tiếng Việt; tên file, ID, frontmatter, tên test, code tiếng Anh.** Nguồn hai lớp: (1) **chỉ thị ban đầu của người dùng 2026-10-14** gồm tên file, ID, frontmatter; (2) **phần mở rộng "tên test, code" do agent đề xuất**, người dùng duyệt ở vòng này (2026-10-14) | Tách hai lớp vì chúng có độ tin cậy khác nhau: lớp 1 là người dùng nói, lớp 2 là agent suy rộng ra rồi mới được duyệt. Chính §C13 bắt được chỗ mở rộng này — xem `docs/learning-log.md` |
| C22 | *(U7)* **8 dòng điều kiện trong "Sẽ thêm khi cần" là điều kiện DỰ KIẾN, xem lại đầu mỗi stage**, không phải luật cứng. Gồm dòng: *bắt đầu stage Dev → agent chạy trong container không có push token* | Điều kiện viết ở Stage 0 là dự đoán về tương lai chưa xảy ra; duyệt chúng thành luật cứng sẽ ràng buộc mình bằng thông tin cũ nhất mình từng có. Dòng container đến từ § "Mô hình mối đe dọa" — biện pháp đã nêu phải có chỗ bám, nếu không tới lúc đó sẽ quên |
| C23 | **Lằn ranh xếp mức cho finding về hook**: lọt bằng cách viết thông thường / fail open / chặn nhầm → **blocking**; chỉ obfuscation có chủ đích → **major** | Người dùng duyệt ở vòng này (2026-10-14) khi chốt kết luận round 2 là "5 blocking". Luật cũ ("vượt được hook → major") mâu thuẫn với chính bản ghi ngay dưới nó. Ranh giới thật nằm ở **phải cố ý tới mức nào mới lọt**, không ở "có lọt hay không" |

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

## Quyết định — xử lý vấn đề còn mở (§O1–§O11) — người dùng chốt 2026-10-14

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
| O10 | `requirements.md` có hai chủ: bảng 6 stage giao vai Architecture, skill PO lại ghi trong phạm vi của mình — mà quy trình trong skill chỉ tạo `intent.md` (review vòng 1 #3) | `requirements.md` thuộc **vai Product Owner**, tạo ở **đầu Stage 2**. `design.md` + ADR thuộc **vai Architecture**. Quy trình requirements trong skill `product-owner` sẽ thêm khi bắt đầu Stage 2 | Biến `intent.md` thành US/AC là việc sản phẩm — ai viết intent thì hiểu rõ nhất ý định đằng sau. Kiến trúc đọc requirements như đầu vào, không tự đặt ra yêu cầu cho mình rồi tự thỏa mãn |
| O11 | Mỗi reviewer dùng thang mức độ riêng (Codex trả `P0`–`P3`, `high`/`medium`/`low`), không gộp lại được để tính ngưỡng dừng | Bảng quy đổi trong AGENTS.md: `critical`/`high`/`P0`/`P1` → blocking; `medium`/`P2` → major; `low`/`P3` → minor. Giữ nhãn gốc trong ngoặc. **Giá trị ban đầu, chỉnh theo learning-log** | Ngưỡng dừng ("0 blocking, ≤2 major") chỉ có nghĩa khi mọi reviewer nói cùng một thang. Giữ nhãn gốc để sau này kiểm lại xem quy đổi có quá nặng tay hay không |

## Mục chưa có nguồn — đã giải quyết hết (2026-10-14)
Rà soát theo §C13 tìm ra 7 luật trong `AGENTS.md` không có nguồn. Người dùng đã chọn
xong cả 7; **không còn mục nào mang dấu ⚠**.

| # | Luật | Kết quả |
|---|---|---|
| U1 | Stage 6 bỏ trống cột "Ai review" | **(a) giữ** → §C17, đánh dấu tạm thời |
| U2 | Sơ đồ "Luồng phối hợp" | **(b) xóa** — trùng nguyên nội dung bảng 6 stage |
| U3 | "Điểm đặc thù của app học tiếng Anh" | **(b) xóa** → §C18 |
| U4 | Template + ID ổn định | **(a) giữ** → §C19 |
| U5 | Không bịa thông tin | **(a) giữ** → §C20 |
| U6 | Quy ước ngôn ngữ | **(a) giữ** → §C21, nguồn ghi hai lớp |
| U7 | 8 điều kiện "Sẽ thêm khi cần" | **(a) giữ** → §C22, là điều kiện dự kiến |

Dấu ⚠ và quy tắc §C13 vẫn giữ trong `AGENTS.md` để dùng cho luật mới thêm sau này —
hiện không luật nào đang mang dấu đó.

## Mô hình mối đe dọa
Viết ra vì hai vòng review đầu cứ xoay quanh hook mà không hội tụ: thiếu mô hình này
thì mọi lỗ hổng đều trông như blocking, và cuộc tranh luận không có điểm dừng.

| | |
|---|---|
| **Hook chống cái gì** | **Nhầm lẫn.** Agent vô tình đổi `status`, hoặc đi tắt vì thấy tiện. Hook làm việc đó thành lỗi rõ ràng thay vì âm thầm trôi qua |
| **Hook KHÔNG chống cái gì** | **Agent cố ý.** Mọi cơ chế khớp chuỗi đều né được: ghép chuỗi, base64, viết script rồi chạy. Đừng dựng thêm lớp vá cho tình huống này — vá không hết |
| **Cổng duyệt thật** | **Merge PR vào `master`, do người làm.** Đó là chỗ duy nhất một thay đổi thực sự được chấp nhận. Hook chỉ là biển báo đặt sớm hơn trên đường |
| **Rủi ro còn lại — chấp nhận ở Stage 0–1** | Agent dùng **chung git credentials** với người dùng, nên về nguyên tắc có thể vượt hook qua Bash và push thẳng. Chấp nhận vì ở Stage 0–1 chưa có code, thiệt hại tối đa là vài file tài liệu — khôi phục được từ git |
| **Biện pháp dự kiến** | Khi bắt đầu **stage Dev**: chạy agent trong container **không có push token**. Lúc đó ranh giới tin cậy nằm ở credentials, đúng chỗ của nó, chứ không nằm ở hook |

**Hệ quả cho việc xếp mức độ:** finding dạng **"vượt được hook"** xếp **major**, không
phải blocking — vì hook vốn không nhận nhiệm vụ chống kẻ cố ý. Finding dạng **"hook
không chạy đúng trong điều kiện bình thường"** (fail open, bắt nhầm việc vô hại) vẫn là
blocking, vì đó là hỏng đúng việc nó nhận làm. Ghi trùng vào
`.agents/skills/qa-review/SKILL.md`.

## Cổng duyệt thật — quyết định cần người
Hook chặn được *tai nạn* và *đường tắt tiện tay*, không chặn được ý định. Những việc
dưới đây **chỉ người dùng làm**, không agent nào được thay:

| Việc | Vì sao máy không thay được |
|---|---|
| Đổi `status: draft` → `approved` (hoặc `accepted`) ở bất kỳ artifact nào | Là hành vi *chịu trách nhiệm*, không phải hành vi *kiểm tra*. Không có cách nào để agent chứng minh với chính nó rằng tài liệu đã đủ tốt |
| Chấp nhận một ADR | Như trên; ADR là nơi ghi "ai đã quyết" |
| Chốt phạm vi MVP, cắt tính năng | Đánh đổi sản phẩm, không có đáp án đúng để agent tìm ra |
| Bỏ qua một gate đang fail | Nếu agent tự bỏ qua được thì gate không còn là gate |

Hệ quả thực tế: mọi quy trình trong repo này kết thúc ở **"dừng lại và báo người dùng"**,
không phải ở "tự duyệt rồi đi tiếp". Nếu một ngày nào đó cần agent tự duyệt một loại
artifact nào đó, phải ghi ADR riêng cho việc đó, nêu rõ chấp nhận rủi ro gì.

## Hệ quả
- Repo nhỏ, mỗi file đang có người dùng. Đổi lại, mỗi lần sang stage mới phải quay lại
  mục "Sẽ thêm khi cần" và ghi thêm ADR.
- README không còn tự mô tả quy trình — ai muốn biết quy trình **phải** mở `AGENTS.md`.
- Symlink `.claude/skills`: môi trường không hỗ trợ symlink (một số checkout Windows) sẽ
  thấy skill rỗng.
- Các ngưỡng gate ở trên chưa có dữ liệu thực tế chống lưng; vòng chạy thật đầu tiên có
  thể cho thấy chúng quá chặt hoặc quá lỏng — lúc đó sửa ADR này, đừng lặng lẽ bỏ qua gate.
- Xóa `reference/` sau khi accept là **một chiều**: phải chắc đã rút hết thứ cần dùng.
- Hook (§C14) có test tự động: `tests/hooks/test_protect_approved.sh`, 20 case gồm cả
  nhánh suy biến (thiếu `jq`, thiếu cả `jq` lẫn `python3`, JSON hỏng → đều fail closed).
  Một case **cố tình khẳng định một lỗ vẫn còn**: lệnh Bash ghép chuỗi `s=appro; ...${s}ved`
  vẫn lọt. Giữ case đó để không ai nhầm hook là ranh giới kín.
- Quy tắc truy vết (§C13) hiện chỉ là **luật mềm**: không có gì chặn một agent ghi thêm
  dòng không nguồn vào AGENTS.md. Thành ràng buộc cứng khi `harness/gates/` có script
  kiểm mọi dòng quyết định đều trỏ tới một ADR tồn tại.

## Việc phải làm khi ADR này được accept
1. Xóa thư mục `reference/`.
2. Đổi `status: draft` → `status: accepted` ở đầu file này.
3. Ghi vào `docs/learning-log.md` điều rút ra từ vòng Stage 0.
4. ~~Xử lý U1–U7~~ — xong 2026-10-14, xem mục "Mục chưa có nguồn — đã giải quyết hết".
