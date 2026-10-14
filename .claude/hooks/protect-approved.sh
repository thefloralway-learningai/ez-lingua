#!/usr/bin/env bash
# Bảo vệ cổng duyệt: chỉ NGƯỜI DÙNG được đưa một tài liệu sang TRẠNG THÁI KẾT THÚC.
#
# Hai bộ từ vựng, cùng một ý nghĩa "đã chốt, agent không sửa nữa":
#   - artifact (intent, requirements, design, tasks): draft → approved
#   - ADR:                        proposed → accepted (hoặc superseded)
# Hook chặn agent chuyển sang BẤT KỲ trạng thái kết thúc nào trong số đó.
#
# Chặn (exit 2) khi:
#   1. File đang sửa đã ở trạng thái kết thúc — không cho sửa tiếp.
#   2. Nội dung SẮP GHI đưa status về một trạng thái kết thúc mà file hiện tại chưa ở
#      đó — tức agent đang tự duyệt sản phẩm của chính nó.
#   3. Hook không tự chạy được (thiếu jq lẫn python3, JSON hỏng) — FAIL CLOSED.
#      Một cổng duyệt mà hỏng thì cho qua là cổng vô dụng.
#
# Đọc nội dung sắp ghi từ tool_input: Write → .content, Edit → .new_string,
# MultiEdit → .edits[].new_string.
#
# Đây là lớp BEST-EFFORT, không phải ranh giới bảo mật. Xem ADR-0001 §C14.

set -u

block() { echo "BLOCKED: $1" >&2; exit 2; }

input=$(cat)

if command -v jq >/dev/null 2>&1; then
  payload=$(printf '%s' "$input" | jq -r '
      ( .tool_input.file_path // "" ),
      ( [ .tool_input.content // empty,
          .tool_input.new_string // empty,
          ( .tool_input.edits // [] | .[]? | .new_string // empty )
        ] | join("\n") )
    ') || block "hook không đọc được tool_input (jq lỗi). Fail closed."
elif command -v python3 >/dev/null 2>&1; then
  payload=$(printf '%s' "$input" | python3 -I -c '
import sys, json
d = json.load(sys.stdin).get("tool_input", {}) or {}
parts = [d.get("content") or "", d.get("new_string") or ""]
for e in (d.get("edits") or []):
    if isinstance(e, dict):
        parts.append(e.get("new_string") or "")
print(d.get("file_path") or "")
print("\n".join(parts))
') || block "hook không đọc được tool_input (python3 lỗi). Fail closed."
else
  block "hook cần jq hoặc python3 để chạy, không có cái nào. Fail closed."
fi

file=$(printf '%s' "$payload" | head -n 1)
new_content=$(printf '%s' "$payload" | tail -n +2)

# Trạng thái kết thúc. `superseded` cũng tính: nói một ADR đã bị thay thế là một
# phán quyết về lịch sử quyết định, không phải việc agent tự kết luận.
FINAL_STATES="approved accepted superseded"

# Tìm dòng `status: <trạng thái kết thúc>` mà không cần grep (dùng pattern match của
# bash), để hook không chết khi PATH tối giản.
approves() {
  local line value st
  while IFS= read -r line; do
    line="${line#"${line%%[![:space:]]*}"}"   # bỏ khoảng trắng đầu
    line="${line%"${line##*[![:space:]]}"}"   # bỏ khoảng trắng cuối
    case "$line" in
      status:*) ;;
      *) continue ;;
    esac
    value="${line#status:}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    for st in $FINAL_STATES; do
      [ "$value" = "$st" ] && return 0
    done
  done <<< "$1"
  return 1
}

# 1. File hiện tại đã approved → khóa.
if [ -n "$file" ] && [ -f "$file" ]; then
  if approves "$(cat "$file")"; then
    block "$file đã ở trạng thái kết thúc. Muốn sửa, người dùng phải đổi status về draft/proposed."
  fi
fi

# 2. Nội dung sắp ghi đưa status lên approved → agent đang tự duyệt.
if approves "$new_content"; then
  block "Chỉ người dùng được đổi status sang approved. Hãy dừng và báo người dùng."
fi

exit 0
