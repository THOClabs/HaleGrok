#!/usr/bin/env node
/** Capture 8×4K stills from /film/:slug and assemble a 2:00 4K master. */
import { chromium } from "playwright";
import { mkdirSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";

const slug = process.argv[2];
const dir = process.argv[3];
const masterName = process.argv[4];
if (!slug || !dir || !masterName) {
  console.error("usage: shoot-episode.mjs <slug> <dir> <master.mp4>");
  process.exit(1);
}

const out = `/workspace/public/films/${dir}`;
mkdirSync(out, { recursive: true });
const browser = await chromium.launch({ args: ["--no-sandbox"] });
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 2 });
for (const sec of [3, 18, 33, 48, 63, 78, 93, 108]) {
  const n = String(Math.floor(sec / 15) + 1).padStart(2, "0");
  await page.goto(`http://127.0.0.1:8080/film/${slug}?t=${sec}`, { waitUntil: "networkidle", timeout: 60000 });
  await page.waitForTimeout(700);
  await page.locator("canvas").screenshot({ path: `${out}/still-${n}.jpg`, type: "jpeg", quality: 94 });
  console.log(slug, "still", n);
}
await browser.close();

const list = [];
for (const n of ["01", "02", "03", "04", "05", "06", "07", "08"]) {
  const clip = `${out}/clip-${n}.mp4`;
  const r = spawnSync(
    "ffmpeg",
    [
      "-y", "-hide_banner", "-loglevel", "error",
      "-loop", "1", "-i", `${out}/still-${n}.jpg`,
      "-vf", "zoompan=z='min(zoom+0.0005,1.05)':d=375:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=3840x2160:fps=25",
      "-t", "15", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "16", "-preset", "veryfast",
      clip,
    ],
    { stdio: "inherit" },
  );
  if (r.status !== 0) process.exit(r.status ?? 1);
  list.push(`file '${clip}'`);
}
const listPath = `/tmp/${slug}-concat.txt`;
writeFileSync(listPath, list.join("\n") + "\n");
const r2 = spawnSync(
  "ffmpeg",
  ["-y", "-hide_banner", "-loglevel", "error", "-f", "concat", "-safe", "0", "-i", listPath, "-c", "copy", `${out}/${masterName}`],
  { stdio: "inherit" },
);
if (r2.status !== 0) process.exit(r2.status ?? 1);
console.log("wrote", `${out}/${masterName}`);
