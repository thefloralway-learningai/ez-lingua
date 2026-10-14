#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gate: nhánh này có sửa file nào đã được duyệt trên master không?

Gate THICK đầu tiên của repo. Hook trong `.claude/hooks/` chỉ canh đường
Edit/Write/MultiEdit **bên trong một session**; ghi qua Bash nằm ngoài phạm vi nó
(ADR-0001 § "Mô hình mối đe dọa", quyết định của người ở round 3). Gate này chạy
**ngoài session**, trên git, nên không quan tâm thay đổi đến từ công cụ nào.

Cách chạy:
    python3 harness/gates/check_status.py [--base master] [--repo .]

Exit 0 = không file đã duyệt nào bị sửa. Exit 1 = có, in tên file.

KNOWN GAP (Stage 0, chưa tự động hóa được):
    Commit do CHÍNH NGƯỜI dùng đổi status cũng bị gate này báo FAIL — nó không
    phân biệt được "người duyệt" với "agent sửa trộm", vì cả hai cùng một tác giả
    git (agent dùng chung credentials). Người kiểm bằng mắt khi duyệt PR.
    Gỡ được khi agent chạy bằng credentials riêng.
"""

import argparse
import subprocess
import sys

FINAL_STATES = {"approved", "accepted", "superseded"}
FENCE = "---"


def run(args, repo):
    return subprocess.run(args, cwd=repo, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def normalize(raw):
    """Giống hệt normalize() của hook: bỏ comment, bỏ quote, trim, lowercase."""
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


def frontmatter_status(text):
    """status trong YAML frontmatter, hoặc None. Chỉ xét khối đầu file."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != FENCE:
        return None
    for i in range(1, len(lines)):
        stripped = lines[i].strip()
        if stripped in (FENCE, "..."):
            for line in lines[1:i]:
                low = line.strip().lower()
                if low.startswith("status:"):
                    return normalize(line.split(":", 1)[1])
            return None
    return None  # mở mà không đóng: không phải frontmatter hợp lệ


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", default="master", help="nhánh gốc (mặc định: master)")
    ap.add_argument("--repo", default=".", help="thư mục repo (mặc định: .)")
    a = ap.parse_args()

    merge_base = run(["git", "merge-base", a.base, "HEAD"], a.repo)
    if merge_base.returncode != 0:
        sys.stderr.write("LỖI: không tìm được merge-base với '%s'.\n%s\n"
                         % (a.base, merge_base.stderr.strip()))
        return 1
    base_sha = merge_base.stdout.strip()

    changed = run(["git", "diff", "--name-only", "%s...HEAD" % a.base], a.repo)
    if changed.returncode != 0:
        sys.stderr.write("LỖI: git diff thất bại.\n%s\n" % changed.stderr.strip())
        return 1

    files = [f for f in changed.stdout.splitlines() if f.strip()]
    offenders = []
    for path in files:
        show = run(["git", "show", "%s:%s" % (base_sha, path)], a.repo)
        if show.returncode != 0:
            continue  # file mới, chưa có trên base
        status = frontmatter_status(show.stdout)
        if status in FINAL_STATES:
            offenders.append((path, status))

    if offenders:
        sys.stderr.write("FAIL: nhánh này sửa %d file đã được duyệt trên '%s':\n"
                         % (len(offenders), a.base))
        for path, status in offenders:
            sys.stderr.write("  %s  (status: %s)\n" % (path, status))
        sys.stderr.write(
            "\nFile đã duyệt là file đã chốt. Muốn sửa thì người dùng đổi status\n"
            "về draft/proposed trong một commit riêng, rồi mới sửa nội dung.\n"
            "\nNGOẠI LỆ chưa tự động hóa được: nếu đây CHÍNH LÀ commit người dùng\n"
            "đổi status, gate vẫn báo FAIL — người kiểm bằng mắt khi duyệt PR.\n")
        return 1

    print("OK: không file đã duyệt nào bị sửa (%d file thay đổi so với '%s')."
          % (len(files), a.base))
    return 0


if __name__ == "__main__":
    sys.exit(main())
