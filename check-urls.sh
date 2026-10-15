# Online link check for `nix run .#check-icon-urls`: every icon.iconUrl, icon.siteUrl and terms.url
# of the catalog index (JSON on $1). iconUrl must answer 200 with an image content-type, at most
# 1 MiB and a known image magic number (the daemon's rules), and have the entry's icon.sha256 (the
# daemon refuses another file); the other URLs must answer 200.
# siteUrl is skipped for firefoxProfile apps (the daemon never fetches it there: those sites refuse
# non-browser requests). Prints a table, exits 1 if any check failed.
set -u
index=$1
max=1048576
ua="Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
fail=0

printf '%-6s %-14s %-9s %-5s %-24s %8s  %s\n' RESULT APP FIELD HTTP TYPE BYTES URL
while IFS=$'\t' read -r app field url sha; do
  code=$(curl -sSL -m 30 --max-filesize $((max + 1)) -A "$ua" -o "$tmp/body" \
    -w '%{http_code}\t%{content_type}' "$url" 2>"$tmp/err") || true
  http=${code%%$'\t'*}
  ctype=${code#*$'\t'}
  [ -f "$tmp/body" ] || : >"$tmp/body"
  size=$(stat -c %s "$tmp/body")
  why=""
  [ "$http" = 200 ] || why="http $http $(tr '\n' ' ' <"$tmp/err")"
  if [ -z "$why" ] && [ "$field" = iconUrl ]; then
    case "$ctype" in image/*) ;; *) why="content-type $ctype is not an image" ;; esac
    [ "$size" -le "$max" ] || why="${why:+$why; }larger than 1 MiB"
    [ "$size" -gt 0 ] || why="${why:+$why; }empty"
    if [ -z "$why" ]; then
      head -c 16 "$tmp/body" | od -An -tx1 | tr -d ' \n' >"$tmp/magic"
      magic=$(cat "$tmp/magic")
      case "$magic" in
        89504e47*|ffd8ff*|47494638*|52494646*|00000100*) ;;
        *) head -c 512 "$tmp/body" | grep -q '<svg' || why="no image magic bytes" ;;
      esac
    fi
    got=$(sha256sum <"$tmp/body" | cut -d' ' -f1)
    [ "$got" = "$sha" ] || why="${why:+$why; }sha256 $got is not icon.sha256 ${sha:-(none)}"
  fi
  if [ -n "$why" ]; then res=FAIL; fail=1; else res=ok; fi
  printf '%-6s %-14s %-9s %-5s %-24s %8s  %s\n' "$res" "$app" "$field" "$http" "${ctype:0:24}" "$size" "$url"
  [ -z "$why" ] || printf '       -> %s\n' "$why"
  rm -f "$tmp/body"
done < <(jq -r '.apps[] | select(.status != "removed") | . as $a |
  ( (.icon.iconUrl // empty) | [$a.id, "iconUrl", ., ($a.icon.sha256 // "")] ),
  ( if .icon.siteUrl and ((.icon.firefoxProfile // false) | not) then [$a.id, "siteUrl", .icon.siteUrl] else empty end ),
  ( (.terms.url // empty) | [$a.id, "terms.url", .] ) | @tsv' "$index")

if [ "$fail" -ne 0 ]; then echo "check-icon-urls: FAILED" >&2; exit 1; fi
echo "check-icon-urls: all ok"
