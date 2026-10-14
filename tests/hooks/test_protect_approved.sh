#!/usr/bin/env bash
# Test cho .claude/hooks/protect-approved.sh và protect-approved-bash.sh
# Chạy: bash tests/hooks/test_protect_approved.sh
# Exit 0 = tất cả pass, 1 = có case fail.

set -u
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
HOOK="$ROOT/.claude/hooks/protect-approved.sh"
HOOK_BASH="$ROOT/.claude/hooks/protect-approved-bash.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0; fail=0; known_gap=0

# run <hook> <mong-doi-exit> <ten-case> <json-stdin>
run() {
  local hook="$1" want="$2" name="$3" json="$4" got
  printf '%s' "$json" | "$hook" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    printf '  ok   %-58s (exit %s)\n' "$name" "$got"; pass=$((pass+1))
  else
    printf '  FAIL %-58s (exit %s, mong doi %s)\n' "$name" "$got" "$want"; fail=$((fail+1))
  fi
}

jstr() { python3 -I -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }

# known_gap <hook> <exit-thuc-te-hien-nay> <ten-case> <json-stdin>
# Dùng cho lỗ hổng ĐÃ BIẾT và CHẤP NHẬN: test khóa lại hành vi hiện tại để nếu ai đó
# vá được thì test đỏ lên và ta biết mà cập nhật tài liệu. KHÔNG tính vào "pass" thường.
known_gap() {
  local hook="$1" want="$2" name="$3" json="$4" got
  printf '%s' "$json" | "$hook" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    printf '  GAP  %-58s (exit %s, lỗ hổng đã biết)\n' "$name" "$got"; known_gap=$((known_gap+1))
  else
    printf '  ???  %-58s (exit %s, truoc day %s)\n' "$name" "$got" "$want"
    printf '       Lo hong nay co ve da duoc va. Cap nhat ADR-0001 §C14 va bo case nay.\n'
    fail=$((fail+1))
  fi
}

DRAFT="$TMP/draft.md"
printf -- '---\nstatus: draft\n---\n# noi dung\n' > "$DRAFT"
APPROVED="$TMP/approved.md"
printf -- '---\nstatus: approved\n---\n# da duyet\n' > "$APPROVED"
NEWFILE="$TMP/moi.md"

APPROVED_BODY=$(printf -- '---\nstatus: approved\n---\n# noi dung\n' | jstr)
DRAFT_BODY=$(printf -- '---\nstatus: draft\n---\n# noi dung moi\n' | jstr)

echo "== protect-approved.sh =="

# 1. draft -> approved qua Edit  => CHAN
run "$HOOK" 2 "Edit doi draft thanh approved" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: approved\"}}"

# 2. draft -> approved qua Write (ghi de ca file) => CHAN
run "$HOOK" 2 "Write ghi de file draft bang noi dung approved" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$DRAFT\",\"content\":$APPROVED_BODY}}"

# 3. draft -> approved qua MultiEdit => CHAN
run "$HOOK" 2 "MultiEdit co mot edit dat status approved" \
  "{\"tool_name\":\"MultiEdit\",\"tool_input\":{\"file_path\":\"$DRAFT\",\"edits\":[{\"old_string\":\"noi dung\",\"new_string\":\"noi dung khac\"},{\"old_string\":\"status: draft\",\"new_string\":\"status: approved\"}]}}"

# 4. sua noi dung khac cua file draft => CHO QUA
run "$HOOK" 0 "Edit sua noi dung khac cua file draft" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"# noi dung\",\"new_string\":\"# noi dung da sua\"}}"

# 5. sua file da approved => CHAN
run "$HOOK" 2 "Edit sua file da approved" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$APPROVED\",\"old_string\":\"# da duyet\",\"new_string\":\"# sua trom\"}}"

# 6. tao file moi voi status: draft => CHO QUA
run "$HOOK" 0 "Write tao file moi co status draft" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$DRAFT_BODY}}"

# --- case bo sung ---

# 7. tao file MOI voi status: approved => CHAN (agent khong duoc sinh ra file da duyet)
run "$HOOK" 2 "Write tao file moi co status approved" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$APPROVED_BODY}}"

# 8. chu "approved" nam trong van xuoi, khong phai dong status => CHO QUA
PROSE=$(printf -- '---\nstatus: draft\n---\nKhi nguoi dung approved thi moi sang stage sau.\n' | jstr)
run "$HOOK" 0 "Noi dung co chu approved nhung khong phai dong status" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$PROSE}}"

# 9. khong co file_path => CHO QUA (hook khong lam vo tool khac)
run "$HOOK" 0 "tool_input khong co file_path" '{"tool_name":"Read","tool_input":{}}'

echo "== trang thai ket thuc cua ADR: accepted / superseded =="

ADR_PROPOSED="$TMP/adr-proposed.md"
printf -- '---\nstatus: proposed\n---\n# ADR-0002\n' > "$ADR_PROPOSED"
ADR_ACCEPTED="$TMP/adr-accepted.md"
printf -- '---\nstatus: accepted\n---\n# ADR-0003\n' > "$ADR_ACCEPTED"
ACCEPTED_BODY=$(printf -- '---\nstatus: accepted\n---\n# noi dung\n' | jstr)

# 14. proposed -> accepted qua Edit => CHAN
run "$HOOK" 2 "Edit doi ADR proposed thanh accepted" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$ADR_PROPOSED\",\"old_string\":\"status: proposed\",\"new_string\":\"status: accepted\"}}"

# 15. proposed -> accepted qua Write => CHAN
run "$HOOK" 2 "Write ghi de ADR proposed bang noi dung accepted" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$ADR_PROPOSED\",\"content\":$ACCEPTED_BODY}}"

# 16. sua ADR da accepted => CHAN
run "$HOOK" 2 "Edit sua ADR da accepted" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$ADR_ACCEPTED\",\"old_string\":\"# ADR-0003\",\"new_string\":\"# sua trom\"}}"

# 17. dat status: superseded => CHAN
run "$HOOK" 2 "Edit dat status superseded" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$ADR_PROPOSED\",\"old_string\":\"status: proposed\",\"new_string\":\"status: superseded\"}}"

# 18. sua noi dung khac cua ADR proposed => CHO QUA
run "$HOOK" 0 "Edit sua noi dung khac cua ADR proposed" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$ADR_PROPOSED\",\"old_string\":\"# ADR-0002\",\"new_string\":\"# ADR-0002: ten moi\"}}"

# 19. status: draft van cho qua (khong phai trang thai ket thuc)
run "$HOOK" 0 "Write file moi status proposed van cho qua" \
  "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$(printf -- '---\nstatus: proposed\n---\n' | jstr)}}"

echo "== bypass tu review vong 2 =="

# R1. Edit chi doi GIA TRI, new_string khong chua chu "status" => CHAN
run "$HOOK" 2 "Edit chi doi gia tri draft->approved" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"draft\",\"new_string\":\"approved\"}}"

# A2a. status co quote => CHAN
run "$HOOK" 2 "status co quote: \"approved\"" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: \\\"approved\\\"\"}}"

# A2b. status co comment YAML => CHAN
run "$HOOK" 2 "status co comment: approved # ghi chu" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: approved # nguoi dung da duyet\"}}"

# A2c. viet hoa => CHAN
run "$HOOK" 2 "status viet hoa: APPROVED" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: APPROVED\"}}"

# A2d. quote + comment + viet hoa cung luc => CHAN
run "$HOOK" 2 "status: 'Accepted'  # xong" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: 'Accepted'  # xong\"}}"

# A2e. chu approved trong comment, khong phai gia tri => CHO QUA
run "$HOOK" 0 "status: draft # cho nguoi dung approved" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: draft # cho nguoi dung approved\"}}"

# MultiEdit chi doi gia tri => CHAN
run "$HOOK" 2 "MultiEdit chi doi gia tri draft->accepted" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"edits\":[{\"old_string\":\"draft\",\"new_string\":\"accepted\"}]}}"

echo "== chi doc status trong YAML frontmatter =="

# Code fence minh hoa 'status: approved' trong tai lieu van la draft => CHO QUA
FENCE_BODY=$(printf -- '---\nstatus: draft\n---\n# Huong dan\n\nVi du frontmatter da duyet:\n\n```\nstatus: approved\n```\n' | jstr)
run "$HOOK" 0 "Code fence chua 'status: approved' van cho qua" \
  "{\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$FENCE_BODY}}"

# Van xuoi co dong 'status: approved' o giua bai => CHO QUA
PROSE2=$(printf -- '---\nstatus: draft\n---\n# Luat\nDoi dong\nstatus: approved\nla viec cua nguoi dung.\n' | jstr)
run "$HOOK" 0 "Van xuoi chua dong 'status: approved' van cho qua" \
  "{\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$PROSE2}}"

# File KHONG co frontmatter => khong phai artifact duoc quan ly => CHO QUA
NOFM=$(printf -- '# Ghi chu\nstatus: approved\n' | jstr)
run "$HOOK" 0 "File khong co frontmatter: cho qua" \
  "{\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$NOFM}}"

# Frontmatter HONG (mo --- khong dong) => FAIL CLOSED
BADFM=$(printf -- '---\nstatus: draft\n# quen dong frontmatter\n' | jstr)
run "$HOOK" 2 "Frontmatter hong (khong dong): fail closed" \
  "{\"tool_input\":{\"file_path\":\"$NEWFILE\",\"content\":$BADFM}}"

# File hien tai co frontmatter hong => cung fail closed
BADFILE="$TMP/bad-frontmatter.md"
printf -- '---\nstatus: draft\nkhong co dong dong\n' > "$BADFILE"
run "$HOOK" 2 "File hien tai frontmatter hong: fail closed" \
  "{\"tool_input\":{\"file_path\":\"$BADFILE\",\"old_string\":\"x\",\"new_string\":\"y\"}}"

echo "== protect-approved-bash.sh =="

# 10. sed doi status => CHAN
run "$HOOK_BASH" 2 "Bash: sed -i doi draft thanh approved" \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"sed -i '' 's/status: draft/status: approved/' $DRAFT\"}}"

# 11. echo >> file => CHAN
run "$HOOK_BASH" 2 "Bash: echo 'status: approved' >> file" \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"echo 'status: approved' >> $DRAFT\"}}"

# 12. lenh binh thuong => CHO QUA
run "$HOOK_BASH" 0 "Bash: lenh git status binh thuong" \
  '{"tool_name":"Bash","tool_input":{"command":"git status --short"}}'

# R2. sed doi gia tri, lenh KHONG chua chu "status" => CHAN
run "$HOOK_BASH" 2 "Bash: sed doi gia tri, khong co chu status" \
  "{\"tool_input\":{\"command\":\"sed -i '' s/draft/approved/ docs/intent.md\"}}"

# Lenh chi DOC co chu approved => CHO QUA
run "$HOOK_BASH" 0 "Bash: grep approved (chi doc)" \
  '{"tool_input":{"command":"grep -rn approved docs/"}}'

# Bash: chan ca accepted
run "$HOOK_BASH" 2 "Bash: sed doi ADR sang accepted" \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"sed -i '' 's/status: proposed/status: accepted/' $ADR_PROPOSED\"}}"

# LỖ HỔNG ĐÃ BIẾT, CÓ CHỦ ĐÍCH GIỮ LẠI.
# Hook Bash so khớp chuỗi thô nên lệnh ghép chuỗi (`s=appro; ... ${s}ved`), base64,
# printf '\x61', biến môi trường hay heredoc đều lọt. Không vá được triệt để bằng
# cách khớp chuỗi — muốn chặn thật thì phải chặn ở tầng khác (permission, sandbox).
# Hook là best-effort, KHÔNG phải ranh giới bảo mật: ADR-0001 §C14 và mục
# "Cổng duyệt thật — quyết định cần người". Test này khóa lại sự thật đó để không ai
# đọc "N pass" rồi tưởng cổng đã kín.
known_gap "$HOOK_BASH" 0 "known_gap_bash_obfuscation" \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"s=appro; echo \\\"status: \${s}ved\\\" >> $DRAFT\"}}"

echo "== nhanh suy bien: PATH toi gian, thieu python3, TMPDIR hong, JSON hong =="

# PATH toi gian: chi co sh + python3. Hook khong con dung jq, grep, tr hay
# file tam nua (review vong 2, finding A1) nen phai chay duoc o day.
NOJQ="$TMP/bin-nojq"; mkdir -p "$NOJQ"
for b in sh python3; do
  src=$(command -v "$b") && [ -x "$src" ] && ln -sf "$src" "$NOJQ/$b"
done

# 14-16. Khong co jq -> phai dung nhanh python3, ket qua y het nhanh jq.
run_env() {
  local path="$1" hook="$2" want="$3" name="$4" json="$5" got
  printf '%s' "$json" | PATH="$path" "$hook" >/dev/null 2>&1
  got=$?
  if [ "$got" -eq "$want" ]; then
    printf '  ok   %-58s (exit %s)\n' "$name" "$got"; pass=$((pass+1))
  else
    printf '  FAIL %-58s (exit %s, mong doi %s)\n' "$name" "$got" "$want"; fail=$((fail+1))
  fi
}

run_env "$NOJQ" "$HOOK" 2 "PATH toi gian (chi sh+python3): van chan" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: approved\"}}"
run_env "$NOJQ" "$HOOK" 0 "PATH toi gian: Edit binh thuong van cho qua" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"new_string\":\"# chi sua tieu de\"}}"
run_env "$NOJQ" "$HOOK_BASH" 2 "PATH toi gian: Bash sed van bi chan" \
  "{\"tool_input\":{\"command\":\"sed -i '' 's/draft/approved/' $DRAFT; echo status\"}}"

# 17-18. Khong co ca jq lan python3 -> FAIL CLOSED (exit 2), khong duoc cho qua.
EMPTY="$TMP/bin-empty"; mkdir -p "$EMPTY"
for b in sh; do
  src=$(command -v "$b") && [ -x "$src" ] && ln -sf "$src" "$EMPTY/$b"
done
run_env "$EMPTY" "$HOOK" 2 "Thieu python3: fail closed (exit 2, khong phai 127)" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"new_string\":\"# vo hai\"}}"
run_env "$EMPTY" "$HOOK_BASH" 2 "Thieu python3 (bash hook): fail closed" \
  '{"tool_input":{"command":"ls"}}'

# TMPDIR khong ghi duoc -> hook van phai chan dung (ban bash cu fail open o day).
TMPRO="$TMP/tmp-readonly"; mkdir -p "$TMPRO"; chmod 500 "$TMPRO"
printf '%s' "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"old_string\":\"status: draft\",\"new_string\":\"status: approved\"}}" \
  | TMPDIR="$TMPRO" "$HOOK" >/dev/null 2>&1
got=$?
if [ "$got" -eq 2 ]; then
  printf '  ok   %-58s (exit %s)\n' "TMPDIR khong ghi duoc: van chan" "$got"; pass=$((pass+1))
else
  printf '  FAIL %-58s (exit %s, mong doi 2)\n' "TMPDIR khong ghi duoc: van chan" "$got"; fail=$((fail+1))
fi
chmod 700 "$TMPRO"

# JSON hong -> FAIL CLOSED.
run "$HOOK" 2 "JSON hong: fail closed" 'khong-phai-json'
run "$HOOK_BASH" 2 "JSON hong (bash hook): fail closed" 'khong-phai-json'

echo
if [ "$known_gap" -gt 0 ]; then
  echo "Ket qua: $pass pass, $fail fail, $known_gap known-gap"
  echo "  known-gap = lo hong da biet va chap nhan, xem ADR-0001 §C14. Khong tinh la pass."
else
  echo "Ket qua: $pass pass, $fail fail"
fi
[ "$fail" -eq 0 ]
