#!/bin/sh
# Wrapper tối giản: gọi protect_approved.py.
#
# Vì sao cần wrapper thay vì để thẳng shebang python3 trong file này:
# Claude Code chỉ coi **exit 2** là chặn. Nếu máy không có python3, shebang
# thất bại và hook thoát 127 — tức KHÔNG chặn, đúng lúc nó phải chặn nhất.
# Wrapper này kiểm python3 trước và tự trả 2 nếu thiếu.
#
# Không dùng here-string hay file tạm (review vòng 2, finding A1).
# Dùng parameter expansion thay `dirname` để wrapper chỉ cần sh + python3.
dir=${0%/*}
[ "$dir" = "$0" ] && dir=.
if command -v python3 >/dev/null 2>&1; then
  exec python3 "$dir/protect_approved.py"
fi
echo "BLOCKED: môi trường không có python3 nên hook không chạy được." >&2
echo "Không kiểm được thao tác Edit/Write này có tự duyệt hay không — fail closed." >&2
echo "Hãy DỪNG và báo người dùng (cần cài python3)." >&2
exit 2
