# -*- coding: utf-8 -*-
"""Parser DUY NHẤT cho `status` trong YAML frontmatter.

Trước đây logic này tồn tại hai bản — một trong hook, một trong gate — và chúng đã
lệch nhau: gate đòi đúng tiền tố `status:` nên bỏ sót `status : approved`, trong khi
hook nhận. Đó là lần thứ tư trong repo này một luật viết ở hai nơi rồi lệch
(review kiểm chứng sau round 3, finding #2). Mọi nơi cần đọc status phải import từ đây.

Quy ước:
  - Chỉ xét khối giữa hai dòng `---` ở ĐẦU file. Ngoài khối đó bỏ qua hoàn toàn:
    một tài liệu nói *về* quy trình duyệt không phải tài liệu đã duyệt.
  - Chịu được khoảng trắng quanh dấu `:`, quote, comment `# ...`, hoa/thường.
  - Mở `---` mà không đóng → BadFrontmatter. Bên gọi tự quyết fail closed hay không.
"""

import re

FINAL_STATES = frozenset({"approved", "accepted", "superseded"})
FENCE = "---"
_STATUS_LINE = re.compile(r"^[ \t]*status[ \t]*:[ \t]*(.*)$", re.IGNORECASE)


class BadFrontmatter(Exception):
    """Frontmatter mở bằng `---` nhưng không có dòng đóng."""


def normalize(raw):
    """Chuẩn hóa giá trị status: bỏ comment, bỏ quote, trim, lowercase.

    `"Approved"  # người dùng duyệt` và `approved` cho ra cùng một kết quả.
    """
    value = raw.strip()
    if value.startswith("#"):
        return ""
    out, quote = [], None
    for i, ch in enumerate(value):
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#" and (i == 0 or value[i - 1] in " \t"):
            break
        else:
            out.append(ch)
    value = "".join(out).strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
        value = value[1:-1].strip()
    return value.lower()


def frontmatter_lines(text):
    """Các dòng trong frontmatter, hoặc None nếu file không có frontmatter."""
    if not text:
        return None
    lines = text.split("\n")
    if not lines or lines[0].strip() != FENCE:
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() in (FENCE, "..."):
            return lines[1:i]
    raise BadFrontmatter("mở bằng `---` ở dòng đầu nhưng không có dòng `---` đóng lại")


def status_of(text):
    """Giá trị status đã chuẩn hóa, hoặc None nếu không có frontmatter/không có status."""
    block = frontmatter_lines(text)
    if block is None:
        return None
    for line in block:
        m = _STATUS_LINE.match(line)
        if m:
            return normalize(m.group(1))
    return None


def is_final(text):
    """Tài liệu có đang ở trạng thái kết thúc không?"""
    return status_of(text) in FINAL_STATES
