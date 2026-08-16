#!/usr/bin/env node
/** Draw Hale wireframes for How Far from the live sim numbers. */
import { chromium } from "playwright";
import { mkdirSync } from "node:fs";
import { HOW_FAR_NUMBERS as N } from "../src/hale/how-far.ts";

mkdirSync("/workspace/public/films/002", { recursive: true });

const pages = [
  {
    file: "wire-01.png",
    title: "Earth — Moon",
    sub: `${N.moonKm.toFixed(0)} km`,
    draw: "moon",
  },
  {
    file: "wire-02.png",
    title: "Earth–Moon rotating frame",
    sub: `μ = ${N.emMu.toExponential(3)}`,
    draw: "em-frame",
  },
  {
    file: "wire-03.png",
    title: "L1 saddle",
    sub: `${N.emL1Km.toFixed(0)} km from Earth`,
    draw: "l1",
  },
  {
    file: "wire-04.png",
    title: "L4 / L5",
    sub: "60° · Routh-stable",
    draw: "triangles",
  },
  {
    file: "wire-05.png",
    title: "Sun–Earth L1",
    sub: `${N.seL1Au.toFixed(4)} AU`,
    draw: "se-l1",
  },
  {
    file: "wire-06.png",
    title: "Sun–Earth L2",
    sub: `${N.seL2Au.toFixed(4)} AU`,
    draw: "se-l2",
  },
  {
    file: "wire-07.png",
    title: "Sun–Jupiter L4",
    sub: `${N.sjL4Au.toFixed(2)} AU`,
    draw: "sj-l4",
  },
  {
    file: "wire-08.png",
    title: "Earth–Mars Hohmann",
    sub: `${N.marsDays.toFixed(1)} d · a = ${N.marsA_AU.toFixed(3)} AU`,
    draw: "mars",
  },
];

const html = (spec) => `<!doctype html>
<html><body style="margin:0;background:#09090b">
<canvas id="c" width="1920" height="1080"></canvas>
<script>
const N = ${JSON.stringify(N)};
const spec = ${JSON.stringify(spec)};
const c = document.getElementById("c");
const ctx = c.getContext("2d");
ctx.fillStyle = "#09090b";
ctx.fillRect(0,0,1920,1080);
ctx.strokeStyle = "#d4d0c8";
ctx.fillStyle = "#ece8e1";
ctx.lineWidth = 1.25;

function disc(x,y,r,fill) {
  ctx.beginPath(); ctx.arc(x,y,r,0,Math.PI*2);
  ctx.fillStyle = fill || "#ece8e1"; ctx.fill();
}
function label(x,y,t) {
  ctx.font = "22px ui-sans-serif, system-ui";
  ctx.fillStyle = "#8a8680";
  ctx.fillText(t,x,y);
}
function line(a,b) {
  ctx.beginPath(); ctx.moveTo(a[0],a[1]); ctx.lineTo(b[0],b[1]); ctx.stroke();
}
function dash(a,b) {
  ctx.save(); ctx.setLineDash([6,7]); line(a,b); ctx.restore();
}

const W=1920,H=1080,cx=960,cy=560;

if (spec.draw === "moon") {
  disc(520, cy, 28, "#6ea0d0");
  disc(1480, cy, 8, "#c8c2b4");
  dash([548,cy],[1472,cy]);
  label(520-18, cy+58, "Earth");
  label(1480-22, cy+48, "Moon");
  label(cx-80, cy-24, N.moonKm.toFixed(0) + " km");
}
if (spec.draw === "em-frame" || spec.draw === "l1" || spec.draw === "triangles") {
  const mu = N.emMu;
  const scale = 620;
  const x1 = cx - mu*scale, x2 = cx + (1-mu)*scale;
  disc(x1, cy, 16, "#6ea0d0");
  disc(x2, cy, 6, "#c8c2b4");
  const L1 = [cx + (N.emL1Km/N.moonKm - 0.5)*scale*1.15, cy];
  // place L points relative to barycenter visually
  const p1 = [x1,cy], p2 = [x2,cy];
  const mid = [(x1+x2)/2, cy];
  const L1x = x1 + (N.emL1Km/N.moonKm)*(x2-x1);
  const L2x = x2 + 0.16*(x2-x1);
  const L3x = x1 - 0.18*(x2-x1);
  const h = (x2-x1)*Math.sqrt(3)/2;
  const L4 = [(x1+x2)/2, cy-h];
  const L5 = [(x1+x2)/2, cy+h];
  ctx.strokeStyle = "#3a3936";
  dash(p1,p2);
  if (spec.draw !== "l1") {
    dash(p1,L4); dash(p2,L4); dash(p1,L5); dash(p2,L5);
  }
  ctx.strokeStyle = "#d4d0c8";
  const pts = spec.draw === "l1"
    ? [["L1", L1x, cy]]
    : spec.draw === "triangles"
      ? [["L4", L4[0], L4[1]], ["L5", L5[0], L5[1]]]
      : [["L1", L1x, cy],["L2", L2x, cy],["L3", L3x, cy],["L4", L4[0], L4[1]],["L5", L5[0], L5[1]]];
  for (const [name,x,y] of pts) {
    disc(x,y,4,"#ece8e1");
    label(x+10,y-10,name);
  }
  label(x1-18, cy+48, "m1");
  label(x2-10, cy+48, "m2");
}
if (spec.draw === "se-l1" || spec.draw === "se-l2") {
  disc(240, cy, 46, "#f0d38a");
  disc(1180, cy, 10, "#6ea0d0");
  dash([286,cy],[1170,cy]);
  const lx = spec.draw === "se-l1" ? 1180 - 90 : 1180 + 90;
  disc(lx, cy, 4);
  label(220, cy+70, "Sun");
  label(1160, cy+48, "Earth");
  label(lx-10, cy-18, spec.draw === "se-l1" ? "L1" : "L2");
  label(lx-40, cy+48, spec.draw === "se-l1" ? N.seL1Au.toFixed(4)+" AU" : N.seL2Au.toFixed(4)+" AU");
}
if (spec.draw === "sj-l4") {
  disc(cx, cy, 14, "#f0d38a");
  const R = 340;
  ctx.beginPath(); ctx.arc(cx,cy,R,0,Math.PI*2); ctx.strokeStyle="#3a3936"; ctx.stroke();
  const j = [cx+R, cy];
  const ang = -Math.PI/3;
  const L4 = [cx+R*Math.cos(ang), cy+R*Math.sin(ang)];
  disc(j[0], j[1], 8, "#d8b48a");
  disc(L4[0], L4[1], 5);
  ctx.strokeStyle = "#d4d0c8";
  dash([cx,cy], j); dash([cx,cy], L4); dash(j, L4);
  label(j[0]+12, j[1]+6, "Jupiter");
  label(L4[0]-10, L4[1]-16, "L4");
  label(cx-16, cy+36, "Sun");
}
if (spec.draw === "mars") {
  disc(cx, cy, 12, "#f0d38a");
  ctx.strokeStyle = "#3a3936";
  ctx.beginPath(); ctx.ellipse(cx,cy,260,260,0,0,Math.PI*2); ctx.stroke();
  ctx.beginPath(); ctx.ellipse(cx,cy,396,396,0,0,Math.PI*2); ctx.stroke();
  ctx.strokeStyle = "#d4d0c8";
  ctx.beginPath(); ctx.ellipse(cx+68,cy,328,250,0,0,Math.PI*2); ctx.stroke();
  disc(cx+260, cy, 5, "#6ea0d0");
  disc(cx-396, cy, 5, "#c06040");
  label(cx+268, cy-12, "Earth");
  label(cx-430, cy-12, "Mars");
  label(cx-40, cy+24, "Sun");
}

ctx.fillStyle = "#ece8e1";
ctx.font = "500 42px ui-serif, Georgia, serif";
ctx.fillText(spec.title, 72, 88);
ctx.font = "22px ui-sans-serif, system-ui";
ctx.fillStyle = "#8a8680";
ctx.fillText(spec.sub, 72, 126);
ctx.fillText("Hale / Ada  ·  How Far", 72, 1028);
</script></body></html>`;

const browser = await chromium.launch({ args: ["--no-sandbox"] });
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 }, deviceScaleFactor: 1 });
for (const spec of pages) {
  await page.setContent(html(spec), { waitUntil: "load" });
  await page.locator("canvas").screenshot({ path: `/workspace/public/films/002/${spec.file}` });
  console.log("wrote", spec.file);
}
await browser.close();
