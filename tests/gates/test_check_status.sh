#!/usr/bin/env bash
# Test cho harness/gates/check_status.py. Dựng repo git tạm cho từng kịch bản.
# Chạy: bash tests/gates/test_check_status.sh

set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
GATE="$ROOT/harness/gates/check_status.py"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0; known_gap=0

# Dựng repo: master có sẵn file, rồi sang nhánh work.
new_repo() {
  local d="$TMP/$1"; mkdir -p "$d"; cd "$d" || exit 1
  git init -q -b master .
  git config user.email t@t; git config user.name t
}

check() {
  local want="$1" name="$2" got
  python3 "$GATE" --base master --repo "$PWD" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    printf '  ok   %-56s (exit %s)\n' "$name" "$got"; pass=$((pass+1))
  else
    printf '  FAIL %-56s (exit %s, mong doi %s)\n' "$name" "$got" "$want"; fail=$((fail+1))
  fi
}

echo "== check_status.py =="

# 1. Sua file da approved tren master => FAIL
new_repo r1
printf -- '---\nstatus: approved\n---\n# da duyet\n' > intent.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '---\nstatus: approved\n---\n# da duyet, bi sua trom\n' > intent.md
git commit -qam edit
check 1 "Sua file da approved tren master"

# 2. Sua file draft => OK
new_repo r2
printf -- '---\nstatus: draft\n---\n# nhap\n' > intent.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '---\nstatus: draft\n---\n# nhap, sua tiep\n' > intent.md
git commit -qam edit
check 0 "Sua file draft"

# 3. Them file moi (chua co tren master) => OK
new_repo r3
printf -- '---\nstatus: draft\n---\n# a\n' > a.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '---\nstatus: approved\n---\n# b\n' > b.md
git add -A && git commit -qm add
check 0 "Them file moi, ke ca co status approved"

# 4. ADR accepted / superseded cung tinh
for st in accepted superseded; do
  new_repo "r4-$st"
  printf -- '---\nstatus: %s\n---\n# ADR\n' "$st" > adr.md
  git add -A && git commit -qm base
  git checkout -qb work
  printf -- '---\nstatus: %s\n---\n# ADR bi sua\n' "$st" > adr.md
  git commit -qam edit
  check 1 "Sua file da $st"
done

# 5. status co quote / comment / viet hoa => van bat duoc
new_repo r5
printf -- '---\nstatus: "Approved"  # nguoi dung duyet\n---\n# x\n' > intent.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '---\nstatus: "Approved"  # nguoi dung duyet\n---\n# x bi sua\n' > intent.md
git commit -qam edit
check 1 "status co quote + comment + viet hoa"

# 6. 'status: approved' ngoai frontmatter => KHONG tinh (giong hook)
new_repo r6
printf -- '---\nstatus: draft\n---\n# Huong dan\n```\nstatus: approved\n```\n' > guide.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '---\nstatus: draft\n---\n# Huong dan v2\n```\nstatus: approved\n```\n' > guide.md
git commit -qam edit
check 0 "status: approved trong code fence, khong tinh"

# 7. File khong co frontmatter => OK
new_repo r7
printf -- '# Ghi chu\nstatus: approved\n' > note.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '# Ghi chu v2\nstatus: approved\n' > note.md
git commit -qam edit
check 0 "File khong co frontmatter"

# 8. Xoa file da approved => FAIL (xoa cung la sua)
new_repo r8
printf -- '---\nstatus: approved\n---\n# x\n' > intent.md
printf -- 'giu cho repo khong rong\n' > keep.md
git add -A && git commit -qm base
git checkout -qb work
git rm -q intent.md
git commit -qm delete
check 1 "Xoa file da approved"

# 9. Khong co thay doi gi => OK
new_repo r9
printf -- '---\nstatus: approved\n---\n# x\n' > intent.md
git add -A && git commit -qm base
git checkout -qb work
check 0 "Nhanh khong co thay doi"

# 10. base khong ton tai => loi, exit 1
new_repo r10
printf -- '# x\n' > a.md
git add -A && git commit -qm base
python3 "$GATE" --base khong-ton-tai --repo "$PWD" >/dev/null 2>&1
got=$?
if [ "$got" -eq 1 ]; then
  printf '  ok   %-56s (exit %s)\n' "Base khong ton tai: bao loi" "$got"; pass=$((pass+1))
else
  printf '  FAIL %-56s (exit %s, mong doi 1)\n' "Base khong ton tai: bao loi" "$got"; fail=$((fail+1))
fi

# 11. KNOWN GAP: commit do CHINH NGUOI dung doi status cung bi bao FAIL.
#     Gate khong phan biet duoc "nguoi duyet" voi "agent sua trom" vi dung chung
#     credentials git. Nguoi kiem bang mat khi duyet PR. Xem docstring cua gate.
new_repo r11
printf -- '---\nstatus: approved\n---\n# x\n' > intent.md
git add -A && git commit -qm base
git checkout -qb work
printf -- '---\nstatus: draft\n---\n# x\n' > intent.md
git commit -qam "nguoi dung mo lai de sua"
python3 "$GATE" --base master --repo "$PWD" >/dev/null 2>&1
got=$?
if [ "$got" -eq 1 ]; then
  printf '  GAP  %-56s (exit %s, lỗ hổng đã biết)\n' "known_gap_human_reopen_flagged" "$got"
  known_gap=$((known_gap+1))
else
  printf '  ???  %-56s (exit %s, truoc day 1)\n' "known_gap_human_reopen_flagged" "$got"
  printf '       Gate co ve da phan biet duoc nguoi/agent. Cap nhat docstring va bo case nay.\n'
  fail=$((fail+1))
fi

cd "$ROOT" || exit 1
echo
if [ "$known_gap" -gt 0 ]; then
  echo "Ket qua: $pass pass, $fail fail, $known_gap known-gap"
  echo "  known-gap = lo hong da biet va chap nhan, xem docstring harness/gates/check_status.py."
else
  echo "Ket qua: $pass pass, $fail fail"
fi
[ "$fail" -eq 0 ]
