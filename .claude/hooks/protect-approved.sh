#!/usr/bin/env bash
# Chặn Claude sửa tài liệu đã được người duyệt (có dòng "status: approved").
input=$(cat)
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
  file=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))')
fi
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0
if grep -qE '^status:[[:space:]]*approved' "$file"; then
  echo "BLOCKED: $file đã được duyệt. Muốn sửa, người dùng phải đổi status về draft." >&2
  exit 2
fi
exit 0
