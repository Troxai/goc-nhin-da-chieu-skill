#!/usr/bin/env bash
# Cài skill "social-video" (kênh Góc Nhìn Đa Chiều) trên macOS.
# Chạy:  bash install.sh        (chạy lại nhiều lần cũng được — không ghi đè cấu hình/secrets đã có)
set -euo pipefail
REPO="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$HOME/.claude/skills/social-video"
WS="$HOME/goc-nhin"
ok()   { printf "\033[32m✔ %s\033[0m\n" "$*"; }
warn() { printf "\033[33m⚠ %s\033[0m\n" "$*"; }
step() { printf "\n\033[1m== %s\033[0m\n" "$*"; }

[[ "$(uname)" == "Darwin" ]] || warn "Script viết cho macOS — máy này không phải Mac, có thể phải sửa tay."

step "1/7 Homebrew"
if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "brew $(brew --version | head -1)"

step "2/7 Phần mềm: node, python, ffmpeg, jq, flock, Chrome"
brew install node python@3.12 ffmpeg jq flock git >/dev/null
[[ -d "/Applications/Google Chrome.app" ]] || brew install --cask google-chrome
command -v claude >/dev/null || npm install -g @anthropic-ai/claude-code
ok "node $(node -v), $(python3 --version), ffmpeg, Chrome, Claude Code"

step "3/7 Thư viện Python"
python3 -m pip install --user --break-system-packages -q pillow numpy requests pyyaml \
  google-api-python-client google-auth-oauthlib google-auth-httplib2
if [[ ! -x "$HOME/whisper-venv/bin/python" ]]; then python3 -m venv "$HOME/whisper-venv"; fi
"$HOME/whisper-venv/bin/pip" install -q faster-whisper numpy
ok "pillow, numpy, google-api, faster-whisper (~/whisper-venv)"

step "4/7 Giọng đọc VieNeu"
if [[ -x "$HOME/VieNeu-TTS/.venv/bin/python" ]] && "$HOME/VieNeu-TTS/.venv/bin/python" -c "import vieneu" 2>/dev/null; then
  ok "VieNeu có sẵn ở ~/VieNeu-TTS"
else
  warn "Chưa thấy VieNeu ở ~/VieNeu-TTS/.venv — cài VieNeu-TTS vào đúng thư mục này (xem README mục 'Giọng đọc')."
fi

step "5/7 Chép skill vào ~/.claude/skills/social-video"
mkdir -p "$HOME/.claude/skills"
rsync -a --delete "$REPO/social-video/" "$SKILL_DIR/"
ok "skill đã cài"

step "6/7 Tạo workspace ~/goc-nhin"
mkdir -p "$WS"/{runs,logs,secrets,channels,config,.claude}
chmod 700 "$WS/secrets"
rsync -a "$SKILL_DIR/scripts/" "$WS/scripts/"
rsync -a --ignore-existing "$SKILL_DIR/assets/template/" "$WS/template/"
rsync -a --ignore-existing "$SKILL_DIR/assets/channels/" "$WS/channels/"
[[ -f "$WS/config/env" ]] || cp "$SKILL_DIR/assets/config/env.example" "$WS/config/env"
cp "$SKILL_DIR/assets/config/crontab.txt" "$WS/config/crontab.txt"
[[ -f "$WS/.claude/settings.json" ]] || cp "$SKILL_DIR/assets/config/claude-settings.json" "$WS/.claude/settings.json"
[[ -f "$WS/package.json" ]] || cp "$SKILL_DIR/assets/workspace-package.json" "$WS/package.json"
chmod +x "$WS"/scripts/*.sh 2>/dev/null || true
(cd "$WS" && npm install --silent)
(cd "$WS/template" && npm install --silent)
ok "workspace sẵn sàng"

step "7/7 Kiểm tra"
(cd "$WS/template" && npx remotion still src/index.ts FptBoard out/test.png --frame=600 --scale=0.25 >/dev/null 2>&1) \
  && ok "Remotion render thử OK (~/goc-nhin/template/out/test.png)" || warn "Remotion render thử lỗi — chạy tay: cd ~/goc-nhin/template && npx remotion still src/index.ts FptBoard out/test.png --frame=600"
for f in youtube_client.json facebook.env; do [[ -f "$WS/secrets/$f" ]] || warn "Thiếu ~/goc-nhin/secrets/$f (cần để đăng bài — README mục 'Tài khoản')"; done

printf "\n\033[1mXONG.\033[0m Bước tiếp theo (README mục 4):\n"
echo "  1. Đăng nhập Google Flow:  cd ~/goc-nhin && node scripts/flow_login.mjs"
echo "  2. Đặt key YouTube/Facebook vào ~/goc-nhin/secrets/"
echo "  3. Mở Claude Code trong ~/goc-nhin và gõ:  /social-video all goc-nhin-da-chieu"
