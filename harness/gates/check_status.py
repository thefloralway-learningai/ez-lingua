#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gate: nhánh này có sửa file nào đã được duyệt trên nhánh gốc không?

Gate THICK đầu tiên của repo. Hook trong `.claude/hooks/` chỉ canh đường
Edit/Write/MultiEdit **bên trong một session**; ghi qua Bash nằm ngoài phạm vi nó
(ADR-0001 § "Mô hình mối đe dọa", quyết định của người ở round 3). Gate này chạy
**ngoài session**, trên git, nên không quan tâm thay đổi đến từ công cụ nào.

Cách chạy:
    python3 harness/gates/check_status.py [--base <nhánh>] [--repo .]

Không truyền --base thì tự dò: origin/HEAD → main → master. Hard-code `master`
đã hỏng một lần khi repo đổi tên nhánh gốc sang `main`.

Exit 0 = không file đã duyệt nào bị sửa. Exit 1 = có, in tên file.

KNOWN GAP (Stage 0, chưa tự động hóa được):
    Commit do CHÍNH NGƯỜI dùng đổi status cũng bị gate này báo FAIL — nó không
    phân biệt được "người duyệt" với "agent sửa trộm", vì cả hai cùng một tác giả
    git (agent dùng chung credentials). Người kiểm bằng mắt khi duyệt PR.
    Gỡ được khi agent chạy bằng credentials riêng.
"""

import argparse
import os
import subprocess
import sys

# Parser status dùng chung với .claude/hooks/protect_approved.py — một bản duy nhất.
sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "lib"))
from frontmatter import BadFrontmatter, FINAL_STATES, status_of  # noqa: E402


def run(args, repo):
    return subprocess.run(args, cwd=repo, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, text=True)


def default_base(repo):
    """Dò nhánh gốc: origin/HEAD → main → master. None nếu không có cái nào."""
    head = run(["git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD"], repo)
    if head.returncode == 0 and head.stdout.strip():
        return head.stdout.strip()
    for name in ("main", "master"):
        if run(["git", "rev-parse", "--verify", "--quiet", name], repo).returncode == 0:
            return name
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base", default=None,
                    help="nhánh gốc (mặc định: tự dò origin/HEAD → main → master)")
    ap.add_argument("--repo", default=".", help="thư mục repo (mặc định: .)")
    a = ap.parse_args()

    if a.base is None:
        a.base = default_base(a.repo)
        if a.base is None:
            sys.stderr.write("LỖI: không dò được nhánh gốc (không có origin/HEAD, main "
                             "hay master). Truyền --base <nhánh>.\n")
            return 1

    merge_base = run(["git", "merge-base", a.base, "HEAD"], a.repo)
    if merge_base.returncode != 0:
        sys.stderr.write("LỖI: không tìm được merge-base với '%s'.\n%s\n"
                         % (a.base, merge_base.stderr.strip()))
        return 1
    base_sha = merge_base.stdout.strip()

    # --no-renames: một lần đổi tên hiện thành D (đường cũ) + A (đường mới), nên
    # `git mv` một file đã duyệt vẫn bị bắt ở nhánh D. Nếu để git gộp thành R thì
    # chỉ thấy đường đích, `git show base:<đích>` thất bại và file lọt như file mới
    # (review kiểm chứng sau round 3, finding #1).
    changed = run(["git", "diff", "--name-status", "--no-renames",
                   "%s...HEAD" % base_sha], a.repo)
    if changed.returncode != 0:
        sys.stderr.write("LỖI: git diff thất bại.\n%s\n" % changed.stderr.strip())
        return 1

    files, offenders = [], []
    for line in changed.stdout.splitlines():
        if not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            continue
        code, path = parts[0].strip(), parts[1]
        files.append(path)
        if code[:1] not in ("M", "D"):
            continue  # A = file mới, chưa từng có trên base
        show = run(["git", "show", "%s:%s" % (base_sha, path)], a.repo)
        if show.returncode != 0:
            continue
        try:
            status = status_of(show.stdout)
        except BadFrontmatter:
            continue  # frontmatter hỏng trên base: không kết luận được, không chặn PR
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
