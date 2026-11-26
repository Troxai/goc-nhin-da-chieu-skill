# Ảnh minh hoạ bằng Google Flow

Script: `node scripts/flow_generate.mjs prompts.json runs/.../images` (Chrome profile trong `config/env` → `CHROME_PROFILE`/`FLOW_PROFILE`, đăng nhập 1 lần bằng `node scripts/flow_login.mjs`). Prompt TIẾNG ANH. Chạy song song 3 prompt (`FLOW_CONC`, tối đa 4), mỗi prompt ra 2 ảnh `<id>_0.jpg`, `<id>_1.jpg`, ~10–15 giây/prompt. Tỉ lệ mặc định 9:16 (`FLOW_RATIO`). Không chạy 2 lệnh flow cùng lúc.
Mã thoát: 0 = xong; 2 / `FLOW_NO_RESULT` = thiếu ảnh → chạy lại cùng lệnh (tối đa 2 lần, tự bỏ qua ảnh đã có); 3 / `FLOW_LOGIN_REQUIRED` = cần đăng nhập lại (`flow_login.mjs`); 4 = giao diện Flow đổi (xem `_flow_error.png`); 5 = chờ khoá Flow quá lâu.
Ảnh Flow có logo ✦ nhỏ góc dưới phải: tách nền + crop sát chủ thể (`chroma_key.py`) sẽ loại nó; kiểm bằng mắt, còn thì crop thêm.

## Prompt (tiếng Anh, luôn kèm khung chung)
Khung chung: `Vertical 9:16 cinematic editorial documentary photograph, 35mm lens, natural realism, subtle film grain. No readable text, no letters, no numbers, no logos, no signage, no watermark.`

- **Cutout (dùng nhiều nhất)**: `Only the main subject: <người/vật>, <hành động>, full body/full object visible. Isolated on a plain flat pure chroma green background (#00FF00), no environment, no floor shadow, no text, no logo.`
  → `python3 scripts/chroma_key.py in.jpg out.png` (khoá xanh + khử loang + crop). Kiểm tóc, tay, cạnh.
- Người: chỉ nhân vật minh hoạ chung (nhà đầu tư, kỹ sư, lãnh đạo doanh nghiệp, người mua nhà). **Không** tạo người thật, không logo.
- Vật: toà nhà, căn hộ, nhà phố, hợp đồng, tiền giấy chung chung, container, nhà máy, bản đồ trơn.
- **Không dùng ảnh nguyên tấm / ảnh cảnh có phông.** Mọi ảnh đều là cutout. Muốn có bối cảnh thì đưa vật thể vào chủ thể: `Only the main subject: a Vietnamese woman handing cash across a small glass gold shop counter with a digital scale, ...` trên nền #00FF00.
- Phong cách được chuyển sang sepia/trắng đen trong Remotion, nên ánh sáng tự nhiên là đủ.

## Thư viện
Ảnh tốt sau khi tách nền → copy vào `template/public/library/` và thêm vào `library.json` (`file`, `tags`, `kind: person|building|object`).
Mỗi video tạo mới 8–12 ảnh cutout đúng câu từng trạm; không dùng lại ảnh nhân vật cũ. Thư viện chỉ cho logo kênh hoặc khi Flow lỗi.


## Khi Flow lỗi
Exit 3 → báo người dùng "Flow cần đăng nhập lại" (`node scripts/flow_login.mjs`). Exit 4 hoặc Flow từ chối hàng loạt (hết lượt, bị giới hạn tạm thời) → không thử quá 2 lần, dùng ảnh thư viện, ghi log và báo người dùng.
