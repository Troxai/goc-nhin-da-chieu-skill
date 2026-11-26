# Skill "Góc Nhìn Đa Chiều" — video tài chính tự động cho Claude Code (macOS)

Skill `social-video` giúp Claude Code tự làm **video dọc 9:16 dài ~3 phút** về tài chính (vàng, bitcoin, lãi suất, chứng khoán, bất động sản, vĩ mô) theo phong cách **"tấm bảng vô tận"**:

1. **research**: đọc tin 24 giờ qua, chấm điểm, chọn chủ đề, kiểm số liệu từ ≥ 2 nguồn.
2. **produce**: viết kịch bản (5 kiểu bài xoay vòng), đọc giọng VieNeu, tạo ảnh bằng Google Flow, dựng Remotion, render, QC, làm thumbnail và caption.
3. **publish**: đăng YouTube Shorts, Facebook Reels, TikTok.

---

## 1. Yêu cầu máy

| | Tối thiểu | Khuyên dùng |
|---|---|---|
| Máy | Mac chip Apple M1 | M2/M3/M4 |
| RAM | 16 GB | 32 GB |
| Ổ trống | 30 GB | 50 GB+ (SSD) |
| macOS | 13 Ventura | mới nhất |

Cần thêm:
- Tài khoản **Claude** (gói Pro/Max) để dùng Claude Code.
- Tài khoản **Google** có gói **Google AI Pro**, để tạo ảnh trong Google Flow.
- **VieNeu-TTS** đã cài ở `~/VieNeu-TTS` (giọng đọc tiếng Việt chạy trên máy).
- Kênh YouTube, Facebook Page, TikTok (chỉ cần khi muốn đăng tự động).

Mỗi video mất khoảng 30–60 phút trên Mac M-series. Phần lâu nhất là giọng đọc và render.

---

## 2. Cài đặt (1 lệnh)

Mở **Terminal** rồi chạy:

```bash
git clone https://github.com/Troxai/goc-nhin-da-chieu-skill.git ~/goc-nhin-da-chieu-skill
cd ~/goc-nhin-da-chieu-skill && bash install.sh
```

`install.sh` tự làm hết các việc sau:
- Cài Homebrew, Node, Python 3.12, ffmpeg, jq, flock, Google Chrome, Claude Code.
- Cài thư viện Python (pillow, numpy, google-api…) và faster-whisper (`~/whisper-venv`, dùng để khớp chữ với giọng).
- Kiểm VieNeu.
- Chép skill vào `~/.claude/skills/social-video`.
- Tạo thư mục làm việc `~/goc-nhin`, cài Remotion và Playwright.
- Render thử một khung hình để kiểm tra.

Chạy lại `install.sh` bao nhiêu lần cũng được. Script không ghi đè `config/env`, `secrets/` hay các video đã làm. **Muốn cập nhật skill:** `cd ~/goc-nhin-da-chieu-skill && git pull && bash install.sh`.

### Giọng đọc (VieNeu)
Skill gọi `~/VieNeu-TTS/.venv/bin/python` với giọng **"Thanh Bình"**, style `doc_truyen`. Nếu VieNeu cài ở chỗ khác, tạo đường dẫn tắt:
```bash
ln -s /duong/dan/VieNeu-TTS ~/VieNeu-TTS
~/VieNeu-TTS/.venv/bin/python -c "import vieneu; print('VieNeu OK')"
```
Muốn đổi giọng thì sửa dòng `voice:` trong `~/goc-nhin/channels/goc-nhin-da-chieu.yaml`.

---

## 3. Cấu trúc sau khi cài

```
~/.claude/skills/social-video/      ← skill (Claude đọc SKILL.md)
  SKILL.md                          quy trình research / produce / publish
  reference/script.md               cách viết kịch bản, 5 kiểu bài
  reference/style.md, images.md…    phong cách hình, ảnh, factcheck, đăng bài
~/goc-nhin/                         ← thư mục làm việc
  channels/goc-nhin-da-chieu.yaml   cấu hình kênh: chủ đề, nguồn tin, giọng, nền tảng
  config/env                        đường dẫn Chrome, profile Flow
  secrets/                          key YouTube/Facebook/Telegram (tự tạo, chmod 700)
  template/                         dự án Remotion
  scripts/                          script Flow, TTS, render, đăng bài…
  runs/<ngày>/<kênh>/               mỗi video 1 thư mục: brief, script, voice, images, final.mp4, post.json, log.md
```

---

## 4. Thiết lập lần đầu

### 4.1 Đăng nhập Google Flow (bắt buộc)
```bash
cd ~/goc-nhin && node scripts/flow_login.mjs
```
Chrome mở ra trang Flow. Đăng nhập tài khoản Google có gói AI Pro, tạo thử 1 ảnh cho chắc, rồi **đóng cửa sổ Chrome**. Phiên đăng nhập được lưu trong profile (`config/env` → `CHROME_PROFILE`), nên các lần sau script tự dùng.

### 4.2 Key đăng bài (chỉ cần khi muốn đăng tự động)
Đặt các file sau vào `~/goc-nhin/secrets/`, rồi chạy `chmod 600 ~/goc-nhin/secrets/*`.

**YouTube**: `youtube_client.json`
1. Vào https://console.cloud.google.com, tạo project, rồi bật **YouTube Data API v3**.
2. Vào *APIs & Services → OAuth consent screen*: chọn External, thêm email của mình vào Test users.
3. Vào *Credentials → Create credentials → OAuth client ID → Desktop app*, tải file JSON về rồi đổi tên thành `youtube_client.json`.
4. Lần đăng đầu tiên, script mở link đăng nhập. Đăng nhập kênh YouTube, script tự tạo `youtube_token.json`.

**Facebook Page**: `facebook.env`
```
FB_PAGE_ID=123456789012345
FB_PAGE_TOKEN=EAAG...        # Page access token dài hạn, quyền pages_manage_posts, pages_read_engagement, publish_video
FB_API=v21.0
```
Cách lấy: https://developers.facebook.com, tạo App (Business), rồi dùng Graph API Explorer lấy User token có các quyền trên, đổi sang token dài hạn, rồi gọi `/me/accounts` để lấy Page token.

**TikTok** (tuỳ chọn): chạy `node scripts/flow_login.mjs https://www.tiktok.com/login`, đăng nhập TikTok trong cùng cửa sổ Chrome, rồi đóng cửa sổ.

**Telegram** (tuỳ chọn, để nhận báo cáo và bản xem trước trên điện thoại): `telegram.env`
```
TG_BOT_TOKEN=123456:ABC...   # tạo bot với @BotFather
TG_CHAT_ID=123456789         # chat id của bạn (nhắn bot rồi xem https://api.telegram.org/bot<TOKEN>/getUpdates)
```
Không có Telegram thì skill vẫn chạy, chỉ bỏ qua bước gửi tin.

### 4.3 Chỉnh kênh
Mở `~/goc-nhin/channels/goc-nhin-da-chieu.yaml`:
- `name`, `topics`, `topic_weights`: chủ đề và mức ưu tiên.
- `sources`: các trang tin để cào.
- `voice`: giọng đọc.
- `platforms`: bật hoặc tắt YouTube, Facebook, TikTok.
- `auto_publish`: `false` (mặc định) thì làm xong chờ bạn duyệt rồi mới đăng; `true` thì tự đăng sau khi QC đạt.
- `publish_time`: giờ đăng.
- Muốn làm kênh khác: chép file yaml thành `<ten-kenh>.yaml`, sửa nội dung, rồi gọi skill với tên kênh mới.

Logo và nhạc của kênh nằm trong `~/goc-nhin/template/public/brand/` và `board-music.m4a`. Thay bằng logo và nhạc của bạn.

---

## 5. Cách dùng hằng ngày

Mở Claude Code **trong thư mục `~/goc-nhin`**:
- **App Claude Desktop**: tab **Code**, chọn thư mục `~/goc-nhin`.
- **Terminal**: `cd ~/goc-nhin && claude`

Rồi gõ lệnh:

| Lệnh | Việc làm |
|---|---|
| `/social-video all goc-nhin-da-chieu` | Làm trọn: chọn tin, dựng video, gửi bản duyệt (hoặc tự đăng nếu `auto_publish: true`) |
| `/social-video research goc-nhin-da-chieu` | Chỉ chọn chủ đề và kiểm số liệu, tạo `brief.json` |
| `/social-video produce goc-nhin-da-chieu` | Dựng video từ brief của hôm nay |
| `/social-video publish goc-nhin-da-chieu` | Đăng video đã duyệt |
| `/social-video all goc-nhin-da-chieu giá vàng SJC` | Làm với chủ đề tự chọn |

Bạn cũng có thể nhắn tự nhiên, ví dụ: *"làm video hôm nay về lãi suất tiết kiệm"*, *"đổi thumbnail video hôm nay"*, *"đăng video hôm qua lên Facebook"*.

**Duyệt và đăng** khi `auto_publish: false`:
1. Xem `~/goc-nhin/runs/<ngày>/goc-nhin-da-chieu/final.mp4` và `post.json` (tiêu đề, mô tả).
2. Muốn sửa thì nhắn Claude, ví dụ "đổi hook", "câu 12 đọc sai tên".
3. Ưng rồi thì nhắn **"OK đăng"**, hoặc chạy `/social-video publish goc-nhin-da-chieu`.

**Kết quả của mỗi video** nằm trong `runs/<ngày>/<kênh>/`: `final.mp4` (video), `thumbnail.jpg`, `post.json` (caption từng nền tảng), `log.md` (Claude đã làm gì, chọn gì, vì sao).

---

## 6. Chạy tự động mỗi ngày (tuỳ chọn)

Máy phải **bật, cắm sạc và không ngủ** vào giờ chạy.

1. Giữ máy không ngủ: System Settings → Battery/Energy → bật "Prevent automatic sleeping", hoặc cài app **Amphetamine**, hoặc chạy `caffeinate -dims &`.
2. Đặt giờ máy về Asia/Ho_Chi_Minh.
3. Cho cron quyền truy cập: System Settings → Privacy & Security → **Full Disk Access**, bấm "+", nhấn ⌘⇧G rồi gõ `/usr/sbin/cron`.
4. `crontab -e` rồi dán (đổi `TEN_BAN` thành tên user Mac của bạn, xem bằng lệnh `whoami`):
```cron
SHELL=/bin/bash
PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/Users/TEN_BAN/.local/bin
30 15 * * * cd ~/goc-nhin && flock -w 3600 .lock claude -p "/social-video all goc-nhin-da-chieu" >> logs/cron.log 2>&1
```
Mỗi ngày 15:30 máy tự làm video. Có Telegram thì bạn nhận bản xem trước để duyệt. Xem nhật ký trong `~/goc-nhin/logs/cron.log`.

Lần đầu chạy `claude -p` từ cron có thể bị chặn quyền. Hãy chạy tay lệnh đó một lần trong Terminal và đồng ý các quyền được hỏi. Quyền mặc định nằm trong `~/goc-nhin/.claude/settings.json`.

---

## 7. Xử lý lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| `FLOW_LOGIN_REQUIRED` / exit 3 | Phiên Google hết hạn: chạy lại `node scripts/flow_login.mjs` |
| Flow exit 4 | Giao diện Flow đổi. Xem ảnh `_flow_error.png` trong thư mục ảnh, báo người bảo trì skill |
| Flow từ chối mọi prompt | Hết lượt hoặc tài khoản bị giới hạn tạm thời. Đợi vài giờ hoặc kiểm tra gói AI Pro |
| `ModuleNotFoundError: vieneu` | VieNeu chưa đúng chỗ, xem mục 2 "Giọng đọc" |
| Giọng đọc rất chậm | Bình thường trên Mac (VieNeu chạy CPU/MPS). Để máy chạy, đừng tắt |
| Render lỗi hoặc nhấp nháy | `cd ~/goc-nhin && python3 scripts/render_safe.py <Comp> out.mp4` (tự render lại các khung lỗi) |
| YouTube `invalid_grant` | Xoá `secrets/youtube_token.json` rồi đăng lại để đăng nhập lại |
| Facebook `OAuthException` | Page token hết hạn, lấy token mới |
| Cron không chạy | Kiểm Full Disk Access cho cron, máy có đang ngủ không, và `logs/cron.log` |

Kiểm tra nhanh môi trường:
```bash
node -v && python3 --version && ffmpeg -version | head -1
~/whisper-venv/bin/python -c "import faster_whisper; print('whisper OK')"
~/VieNeu-TTS/.venv/bin/python -c "import vieneu; print('VieNeu OK')"
cd ~/goc-nhin/template && npx remotion still src/index.ts FptBoard out/test.png --frame=600
```

---

## 8. Lưu ý nội dung
- Kênh tài chính: skill **không** khuyên mua/bán, không dự báo giá mục tiêu, không gợi ý sàn hay coin. Mọi con số phải kiểm từ ≥ 2 nguồn.
- Repo **không chứa** key, token hay mật khẩu. Không bao giờ commit thư mục `secrets/`.
