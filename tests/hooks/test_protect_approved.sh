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

pass=0; fail=0

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

# Bash: chan ca accepted
run "$HOOK_BASH" 2 "Bash: sed doi ADR sang accepted" \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"sed -i '' 's/status: proposed/status: accepted/' $ADR_PROPOSED\"}}"

# GHI NHAN HAN CHE: ghep chuoi van lot. Hook la best-effort, khong phai ranh gioi
#     bao mat (ADR-0001 §C14). Test nay khoa lai su that do de khong ai tuong nham.
run "$HOOK_BASH" 0 "Bash: ghep chuoi VAN LOT (han che da biet, co y)" \
  "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"s=appro; echo \\\"status: \${s}ved\\\" >> $DRAFT\"}}"

echo "== nhanh suy bien: fail closed =="

# Thu muc PATH toi gian, co python3 nhung KHONG co jq.
NOJQ="$TMP/bin-nojq"; mkdir -p "$NOJQ"
for b in bash cat head tail python3; do
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

run_env "$NOJQ" "$HOOK" 2 "Khong co jq: Edit dat status approved van bi chan" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"new_string\":\"status: approved\"}}"
run_env "$NOJQ" "$HOOK" 0 "Khong co jq: Edit binh thuong van cho qua" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"new_string\":\"# chi sua tieu de\"}}"
run_env "$NOJQ" "$HOOK_BASH" 2 "Khong co jq: Bash sed doi approved van bi chan" \
  "{\"tool_input\":{\"command\":\"sed -i '' 's/draft/approved/' $DRAFT; echo status\"}}"

# 17-18. Khong co ca jq lan python3 -> FAIL CLOSED (exit 2), khong duoc cho qua.
EMPTY="$TMP/bin-empty"; mkdir -p "$EMPTY"
for b in bash cat head tail; do
  src=$(command -v "$b") && [ -x "$src" ] && ln -sf "$src" "$EMPTY/$b"
done
run_env "$EMPTY" "$HOOK" 2 "Khong co jq lan python3: fail closed" \
  "{\"tool_input\":{\"file_path\":\"$DRAFT\",\"new_string\":\"# vo hai\"}}"
run_env "$EMPTY" "$HOOK_BASH" 2 "Khong co jq lan python3 (bash hook): fail closed" \
  '{"tool_input":{"command":"ls"}}'

# 19-20. JSON hong -> FAIL CLOSED.
run "$HOOK" 2 "JSON hong: fail closed" 'khong-phai-json'
run "$HOOK_BASH" 2 "JSON hong (bash hook): fail closed" 'khong-phai-json'

echo
echo "Ket qua: $pass pass, $fail fail"
[ "$fail" -eq 0 ]
