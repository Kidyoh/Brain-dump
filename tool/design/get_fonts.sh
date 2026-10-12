#!/usr/bin/env bash
# Downloads the static font files the design exploration boards use into
# tool/design/fonts (not committed). All are SIL Open Font License fonts from
# Google Fonts.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p fonts
fetch() {
  local file="$1" spec="$2"
  curl -sS -A "Mozilla/4.0" "https://fonts.googleapis.com/css2?family=${spec}" |
    grep -oE "font-weight: [0-9]+|url\([^)]+\)" | paste - - |
    while read -r _ w url; do
      url="${url#url(}"; url="${url%)}"
      curl -sS -o "fonts/${file}-w${w%;}.ttf" "$url"
    done
}
fetch Inter "Inter:wght@400;500;600;700;800"
fetch Manrope "Manrope:wght@400;500;600;700;800"
fetch SpaceGrotesk "Space+Grotesk:wght@400;500;600;700"
fetch Bricolage "Bricolage+Grotesque:wght@400;500;600;700;800"
curl -sS -o fonts/InstrumentSerif-Regular.ttf https://fonts.gstatic.com/s/instrumentserif/v5/jizBRFtNs2ka5fXjeivQ4LroWlx-2zI.ttf
curl -sS -o fonts/InstrumentSerif-Italic.ttf https://fonts.gstatic.com/s/instrumentserif/v5/jizHRFtNs2ka5fXjeivQ4LroWlx-6zATiw.ttf
