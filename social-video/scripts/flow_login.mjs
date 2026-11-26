// Mở Chrome (đúng profile mà flow_generate.mjs dùng) tới Google Flow để đăng nhập 1 lần.
// usage: node scripts/flow_login.mjs [url]   — đăng nhập xong thì ĐÓNG cửa sổ Chrome, phiên được lưu lại.
import './load_env.mjs';
import {chromium} from 'playwright';
const E = process.env;
const prof = E.FLOW_PROFILE || E.CHROME_PROFILE;
if (!prof) { console.error('Thiếu FLOW_PROFILE/CHROME_PROFILE trong config/env'); process.exit(1); }
const ctx = await chromium.launchPersistentContext(prof, {headless: false, executablePath: E.CHROME_PATH || undefined, viewport: null});
const page = ctx.pages()[0] || await ctx.newPage();
await page.goto(process.argv[2] || 'https://labs.google/fx/tools/flow');
console.log('Đăng nhập Google trong cửa sổ Chrome vừa mở (nên dùng tài khoản có gói Google AI Pro). Xong thì đóng cửa sổ.');
await new Promise((r) => ctx.on('close', r));
console.log('Đã lưu phiên đăng nhập vào', prof);
