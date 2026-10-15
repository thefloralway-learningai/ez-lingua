#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Guardrail: ngăn agent VÔ Ý đưa một tài liệu sang trạng thái kết thúc.

Giữ đuôi .sh để không phải đổi đường dẫn trong settings.json; nội dung là Python.
Trước đây viết bằng bash, nhưng here-string cần file tạm — TMPDIR hỏng là hook
fail open đúng lúc nó tuyên bố fail closed (review vòng 2, finding A1).

PHẠM VI: chỉ đường Edit/Write/MultiEdit. Ghi qua Bash nằm NGOÀI phạm vi hook —
cái đó do harness/gates/check_status.py canh (ADR-0001 § "Mô hình mối đe dọa",
quyết định của người ở round 3).

ĐÂY LÀ GUARDRAIL CHỐNG NHẦM LẪN, KHÔNG PHẢI RANH GIỚI BẢO MẬT.
Cổng duyệt thật là merge PR vào nhánh gốc do người làm.

Chỉ đọc `status` trong YAML FRONTMATTER (khối giữa hai dòng `---` ở ĐẦU file).
Nội dung ngoài frontmatter bỏ qua hoàn toàn: một tài liệu nói *về* quy trình duyệt
hay có code fence minh họa `status: approved` không phải là tài liệu đã duyệt
(review vòng 3, finding #3 — false positive khiến người ta tắt guardrail).

Chặn (exit 2) khi:
  1. File hiện tại đã ở trạng thái kết thúc.
  2. Tài liệu SAU KHI ÁP THAY ĐỔI ở trạng thái kết thúc mà trước đó thì không.
     Dựng lại nội dung sau sửa, nên một Edit chỉ đổi mỗi giá trị
     (old_string="draft", new_string="approved") vẫn bị bắt.
  3. Bất kỳ lỗi nào khiến hook không kết luận được — fail closed.

Từ vựng: artifact draft→approved; ADR proposed→accepted/superseded.
"""

import json
import os
import sys

STOP = "Hãy DỪNG và báo người dùng."

# Parser status dùng chung với harness/gates/check_status.py — một bản duy nhất,
# để hai nơi không lệch nhau (review kiểm chứng sau round 3, finding #2).
_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, os.path.join(_ROOT, "harness", "lib"))
try:
    from frontmatter import BadFrontmatter, is_final
except Exception as _exc:  # không import được → fail closed
    sys.stderr.write("BLOCKED: hook không nạp được harness/lib/frontmatter.py (%s).\n"
                     "Không xác minh được thao tác — fail closed.\n%s\n" % (_exc, STOP))
    sys.exit(2)


def block(msg):
    sys.stderr.write("BLOCKED: %s\n" % msg)
    sys.exit(2)


def apply_edit(text, old, new, replace_all):
    if old == "":
        return new if text is None else text + new
    if text is None:
        return new
    return text.replace(old, new) if replace_all else text.replace(old, new, 1)


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception as exc:
        block("hook không phân tích được tool_input: JSON hỏng (%s).\n"
              "Không xác minh được thao tác này có tự duyệt hay không — fail closed.\n%s"
              % (exc, STOP))

    ti = (data or {}).get("tool_input") or {}
    path = ti.get("file_path") or ""

    current = None
    if path:
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                current = fh.read()
        except FileNotFoundError:
            current = None
        except OSError as exc:
            block("không đọc được %s (%s).\n"
                  "Không xác minh được trạng thái hiện tại — fail closed.\n%s"
                  % (path, exc, STOP))

    # 1. File hiện tại đã chốt.
    try:
        current_final = is_final(current)
    except BadFrontmatter as exc:
        block("frontmatter của %s hỏng: %s.\n"
              "Không xác minh được trạng thái hiện tại — fail closed.\n%s"
              % (path, exc, STOP))
    if current_final:
        block("%s đã ở trạng thái kết thúc.\n"
              "Muốn sửa, người dùng phải đổi status về draft/proposed." % path)

    # 2. Dựng lại nội dung sau khi áp thay đổi.
    post = current
    if "content" in ti and ti.get("content") is not None:
        post = ti.get("content") or ""
    elif ti.get("edits"):
        edits = ti.get("edits")
        if not isinstance(edits, list):
            block("trường edits không phải danh sách — fail closed.\n%s" % STOP)
        for e in edits:
            if not isinstance(e, dict):
                block("một phần tử edits không phải object — fail closed.\n%s" % STOP)
            post = apply_edit(post, e.get("old_string") or "",
                              e.get("new_string") or "", bool(e.get("replace_all")))
    elif ti.get("new_string") is not None:
        post = apply_edit(post, ti.get("old_string") or "",
                          ti.get("new_string") or "", bool(ti.get("replace_all")))

    try:
        post_final = is_final(post)
    except BadFrontmatter as exc:
        block("frontmatter của nội dung sắp ghi hỏng: %s.\n"
              "Không xác minh được thao tác này có tự duyệt hay không — fail closed.\n%s"
              % (exc, STOP))
    if post_final:
        block("Chỉ người dùng được đổi status sang approved. %s" % STOP)

    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as exc:  # fail closed với mọi lỗi còn lại
        sys.stderr.write("BLOCKED: hook lỗi bất ngờ (%s: %s).\n"
                         "Không xác minh được thao tác — fail closed.\n%s\n"
                         % (type(exc).__name__, exc, STOP))
        sys.exit(2)
