
title() {
  echo
  echo "🔗 ---- $* ----"
}

pause() {
  echo
  local MSG="$*"
  [[ -z "$MSG" ]] && MSG="Hit enter to continue..."
  read -p "$MSG"
}

show-then-run() {
  read -p "\$ $*"
  $*
}

curl-json() {
  curl -s -H "Accept: application/json" $@
}

# Remove the leading type prefix if it's present
trimmed-name() {
  echo "$1" | sed 's#.*/##'
}
