#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Vá đường vòng: agent có thể né protect-approved.sh bằng shell.

Giữ đuôi .sh để không phải đổi đường dẫn trong settings.json; nội dung là Python.

GUARDRAIL CHỐNG NHẦM LẪN, KHÔNG PHẢI RANH GIỚI BẢO MẬT — xem ADR-0001
§ "Mô hình mối đe dọa". Một lệnh cố tình né vẫn lọt (xem KNOWN GAP bên dưới).

Chặn khi lệnh vừa nhắc tới một trạng thái kết thúc, vừa có dấu hiệu GHI:
  - `sed -i 's/status: draft/status: approved/' f`   (có cả hai)
  - `sed -i '' 's/draft/approved/' f`                (không có chữ "status" —
    finding R2 vòng 2; bản bash cũ cho lọt vì đòi phải có chữ "status")
Lệnh chỉ ĐỌC thì cho qua: `grep approved f`, `git log --grep approved`.

KNOWN GAP (có chủ đích, không vá được bằng khớp chuỗi):
  ghép chuỗi `s=appro; ... ${s}ved`, base64, printf '\\x61', biến môi trường,
  heredoc rồi chạy script. Muốn chặn thật thì phải chặn ở tầng credentials
  (ADR-0001 § "Mô hình mối đe dọa" — biện pháp dự kiến: container không có push token).

Mọi lỗi → exit 2, fail closed.
"""

import json
import re
import sys

FINAL_STATES = ("approved", "accepted", "superseded")

# Dấu hiệu lệnh GHI xuống file, không phải chỉ đọc.
WRITE_HINTS = (
    r"\bsed\b[^|]*-i", r"\bperl\b[^|]*-i", r"\bawk\b[^|]*-i",
    r">>", r">", r"\btee\b", r"\btruncate\b", r"\bdd\b",
    r"\bex\b\s", r"\bed\b\s", r"\bpython3?\b", r"\bruby\b", r"\bnode\b",
    r"<<", r"\bcp\b", r"\bmv\b", r"\binstall\b",
)

STOP = "Hãy DỪNG và báo người dùng."


def block(msg):
    sys.stderr.write("BLOCKED: %s\n" % msg)
    sys.exit(2)


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception as exc:
        block("hook không phân tích được tool_input: JSON hỏng (%s).\n"
              "Không kiểm được lệnh này có đổi status hay không — fail closed.\n%s"
              % (exc, STOP))

    cmd = ((data or {}).get("tool_input") or {}).get("command") or ""
    if not cmd:
        sys.exit(0)

    low = cmd.lower()
    state = next((s for s in FINAL_STATES if s in low), None)
    if state is None:
        sys.exit(0)

    if "status" in low or any(re.search(p, low) for p in WRITE_HINTS):
        block("lệnh nhắc tới trạng thái kết thúc '%s' và có dấu hiệu ghi file.\n"
              "Chỉ người dùng được đổi status sang approved/accepted/superseded.\n"
              "(Nếu chỉ ĐỌC, hãy đọc bằng Read thay vì Bash.)\n%s" % (state, STOP))

    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except BaseException as exc:
        sys.stderr.write("BLOCKED: hook lỗi bất ngờ (%s: %s).\n"
                         "Không kiểm được lệnh — fail closed.\n%s\n"
                         % (type(exc).__name__, exc, STOP))
        sys.exit(2)
