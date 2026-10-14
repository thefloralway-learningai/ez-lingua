#!/usr/bin/env bash
# Vá đường vòng: agent có thể né protect-approved.sh bằng shell
# (`sed -i 's/draft/approved/'`, `echo "status: approved" >> file`, python, perl...).
#
# BEST-EFFORT, KHÔNG CHẶN TUYỆT ĐỐI ĐƯỢC. Một lệnh cố tình né vẫn lọt, ví dụ:
#   - ghép chuỗi: `s="appro"; echo "status: ${s}ved" >> f`
#   - base64, printf '\x61...', biến môi trường, đọc từ file khác
#   - heredoc trong script rồi chạy script đó
# Nó chỉ bắt trường hợp thẳng thừng, đủ để biến "lách luật" thành hành vi phải
# cố ý — không phải thành bất khả thi. Cổng duyệt thật là con người.
# Xem ADR-0001 §C14.

set -u
block() { printf 'BLOCKED: %b\n' "$1" >&2; exit 2; }

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""') \
    || block "hook không phân tích được tool_input: jq trả lỗi (JSON hỏng hoặc jq hỏng).\nHook fail closed — không kiểm được lệnh này có đổi status hay không.\nHãy DỪNG và báo người dùng."
elif command -v python3 >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | python3 -I -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command") or "")') \
    || block "hook không phân tích được tool_input: python3 trả lỗi (JSON hỏng hoặc python3 hỏng).\nHook fail closed — không kiểm được lệnh này có đổi status hay không.\nHãy DỪNG và báo người dùng."
else
  block "môi trường thiếu cả jq lẫn python3 nên hook không đọc được tool_input.\nHook fail closed — cổng duyệt không hoạt động được.\nHãy DỪNG và báo người dùng (cần cài jq hoặc python3)."
fi

[ -z "$cmd" ] && exit 0

# So khớp bằng pattern của bash, không gọi grep/tr, để hook sống được với PATH tối
# giản. Dùng nocasematch thay cho ${cmd,,} vì macOS còn bash 3.2.
shopt -s nocasematch
if [[ "$cmd" == *status* ]] && \
   [[ "$cmd" == *approved* || "$cmd" == *accepted* || "$cmd" == *superseded* ]]; then
  echo "BLOCKED: Chỉ người dùng được đổi status sang approved. Hãy dừng và báo người dùng." >&2
  echo "(Lệnh bị chặn vì chứa 'status' cùng một trạng thái kết thúc: approved/accepted/superseded." >&2
  echo " Nếu chỉ đang ĐỌC, hãy đọc bằng Read.)" >&2
  exit 2
fi

exit 0
