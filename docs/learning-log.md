# Learning log

Ghi lại điều rút ra về **quy trình** (không phải về sản phẩm). Mỗi lần thấy quy trình
vướng hoặc chạy tốt bất ngờ thì thêm một dòng. Biện pháp chia hai loại:
**thin** = luật trong tài liệu, dựa vào agent tuân thủ · **thick** = gate chạy bằng máy.

| Ngày | Stage | Điều học được | Biện pháp |
|---|---|---|---|
| 2026-10-14 | 0 — Setup | Draft repo liệt kê cả `harness/`, `.github/workflows/`, 4 skill. Dựng hết ngay sẽ có thư mục rỗng không ai dùng. | **thin**: chỉ dựng phần Stage 1 cần; phần còn lại kèm điều kiện trong AGENTS.md § "Sẽ thêm khi cần" (ADR-0001 §C8). |
| 2026-10-14 | 0 — Setup | README mô tả agent/công cụ ở hai chỗ (bảng agent và mục "Các bước"), hai chỗ nói khác nhau. | **thin**: một nguồn duy nhất — quy trình chỉ nằm ở AGENTS.md, README trỏ sang (ADR-0001 §O1). |
| 2026-10-14 | 0 — Setup | **Agent biến một dòng liệt kê ngắn của người dùng thành "quyết định đã chốt".** Người dùng viết `dev là claude` trong một chuỗi liệt kê không kèm lý do; agent nâng thành dòng quyết định in đậm trong AGENTS.md và ADR-0001, ghi là "người dùng chốt", không hỏi lại và không ghi nguồn. Người dùng phải tự phát hiện khi đọc lại. Rủi ro: quyết định không ai thực sự cân nhắc trôi vào tài liệu nền, rồi các quyết định sau xây lên trên nó. | **thin** (đã làm): quy tắc truy vết — mọi quyết định trong AGENTS.md phải trỏ tới ADR hoặc file review; mục chưa có nguồn mang dấu ⚠ và không tính là đã chốt (ADR-0001 §C13). Rà soát đầu tiên tìm ra 7 mục không nguồn (U1–U7). **thick** (sau này): script trong `harness/gates/` kiểm mọi dòng quyết định đều trỏ tới một ADR tồn tại; CI chạy lại. |
| 2026-10-14 | 0 — Setup | Chốt "ai viết code" mà không có dữ liệu thì chỉ là đoán. Lý do thật để chọn Claude Code là **hook/permission/subagent chỉ có trong `.claude/`**, không phải chất lượng model. | **thin**: ADR-0001 §C12 ghi rõ lý do công cụ, kèm điều kiện xem xét lại khi `harness/gates/` + CI đã chạy — lúc đó ràng buộc nằm ở gate, chọn lại bằng dữ liệu. |
