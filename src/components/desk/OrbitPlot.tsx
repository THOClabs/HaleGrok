import { useEffect, useRef } from "react";
import type { PlotData } from "@/hale/types";

type Props = { plot: PlotData; title: string };

export function OrbitPlot({ plot, title }: Props) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const parent = canvas.parentElement;
    if (!parent) return;

    const draw = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      const w = parent.clientWidth;
      const h = parent.clientHeight;
      if (w < 8 || h < 8) return;
      canvas.width = Math.floor(w * dpr);
      canvas.height = Math.floor(h * dpr);
      canvas.style.width = `${w}px`;
      canvas.style.height = `${h}px`;
      const ctx = canvas.getContext("2d");
      if (!ctx) return;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
      paint(ctx, w, h, plot);
    };

    draw();
    const ro = new ResizeObserver(draw);
    ro.observe(parent);
    return () => ro.disconnect();
  }, [plot]);

  return (
    <div className="relative h-full min-h-72 w-full overflow-hidden bg-bg">
      <canvas ref={ref} className="absolute inset-0" />
      <div className="pointer-events-none absolute left-4 top-4 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
        {title}
      </div>
    </div>
  );
}

function paint(ctx: CanvasRenderingContext2D, w: number, h: number, plot: PlotData) {
  ctx.fillStyle = "#07080a";
  ctx.fillRect(0, 0, w, h);

  // faint field
  ctx.strokeStyle = "rgba(232,230,225,0.04)";
  ctx.lineWidth = 1;
  const g = 48;
  for (let x = 0; x < w; x += g) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, h);
    ctx.stroke();
  }
  for (let y = 0; y < h; y += g) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(w, y);
    ctx.stroke();
  }

  const color = plot.colorHex ?? "#c4a574";
  const pad = 36;
  const box = { x: pad, y: pad, w: w - pad * 2, h: h - pad * 2 };

  if (plot.kind === "cr3bp") {
    paintCr3bp(ctx, box, plot, color);
    return;
  }
  paintHohmann(ctx, box, plot, color);
}

function fit(
  pts: Array<{ x: number; y: number }>,
  box: { x: number; y: number; w: number; h: number },
) {
  let minX = Infinity,
    maxX = -Infinity,
    minY = Infinity,
    maxY = -Infinity;
  for (const p of pts) {
    minX = Math.min(minX, p.x);
    maxX = Math.max(maxX, p.x);
    minY = Math.min(minY, p.y);
    maxY = Math.max(maxY, p.y);
  }
  const span = Math.max(maxX - minX, maxY - minY, 1e-6) * 1.18;
  const cx = (minX + maxX) / 2;
  const cy = (minY + maxY) / 2;
  const s = Math.min(box.w, box.h) / span;
  return (p: { x: number; y: number }) => ({
    x: box.x + box.w / 2 + (p.x - cx) * s,
    y: box.y + box.h / 2 - (p.y - cy) * s,
  });
}

function strokeLoop(
  ctx: CanvasRenderingContext2D,
  pts: Array<{ x: number; y: number }>,
  map: (p: { x: number; y: number }) => { x: number; y: number },
  style: string,
  width: number,
) {
  if (pts.length < 2) return;
  ctx.beginPath();
  const a = map(pts[0]!);
  ctx.moveTo(a.x, a.y);
  for (let i = 1; i < pts.length; i++) {
    const p = map(pts[i]!);
    ctx.lineTo(p.x, p.y);
  }
  ctx.closePath();
  ctx.strokeStyle = style;
  ctx.lineWidth = width;
  ctx.stroke();
}

function paintHohmann(
  ctx: CanvasRenderingContext2D,
  box: { x: number; y: number; w: number; h: number },
  plot: PlotData,
  color: string,
) {
  const pts = [
    ...(plot.innerSamples ?? []),
    ...(plot.outerSamples ?? []),
    ...(plot.transferSamples ?? []),
    { x: 0, y: 0 },
  ];
  const map = fit(pts, box);

  if (plot.innerSamples) strokeLoop(ctx, plot.innerSamples, map, "rgba(232,230,225,0.28)", 1);
  if (plot.outerSamples) strokeLoop(ctx, plot.outerSamples, map, "rgba(232,230,225,0.16)", 1);
  if (plot.transferSamples) strokeLoop(ctx, plot.transferSamples, map, color, 1.6);

  const o = map({ x: 0, y: 0 });
  const earthR = plot.earthR ?? 6378;
  const scalePt = map({ x: earthR, y: 0 });
  const er = Math.max(4, Math.abs(scalePt.x - o.x));
  ctx.beginPath();
  ctx.arc(o.x, o.y, er, 0, Math.PI * 2);
  ctx.fillStyle = "#1c2430";
  ctx.fill();
  ctx.beginPath();
  ctx.arc(o.x, o.y, er * 0.55, 0, Math.PI * 2);
  ctx.fillStyle = "#3d6b4f";
  ctx.fill();
}

function paintCr3bp(
  ctx: CanvasRenderingContext2D,
  box: { x: number; y: number; w: number; h: number },
  plot: PlotData,
  color: string,
) {
  const pts = [
    ...(plot.points ?? []).map((p) => ({ x: p.x, y: p.y })),
    ...(plot.trail ?? []),
    plot.primaries?.p1 ?? { x: 0, y: 0 },
    plot.primaries?.p2 ?? { x: 1, y: 0 },
    { x: 0, y: 0 },
  ];
  const map = fit(pts, box);

  if (plot.trail && plot.trail.length > 1) {
    ctx.beginPath();
    const a = map(plot.trail[0]!);
    ctx.moveTo(a.x, a.y);
    for (let i = 1; i < plot.trail.length; i++) {
      const p = map(plot.trail[i]!);
      ctx.lineTo(p.x, p.y);
    }
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.5;
    ctx.stroke();
  }

  if (plot.primaries) {
    const a = map(plot.primaries.p1);
    const b = map(plot.primaries.p2);
    ctx.beginPath();
    ctx.moveTo(a.x, a.y);
    ctx.lineTo(b.x, b.y);
    ctx.strokeStyle = "rgba(232,230,225,0.18)";
    ctx.stroke();
    disk(ctx, a.x, a.y, 7, "#e8e2d4");
    disk(ctx, b.x, b.y, 4, color);
  }

  for (const p of plot.points ?? []) {
    const q = map(p);
    ctx.beginPath();
    ctx.arc(q.x, q.y, 3, 0, Math.PI * 2);
    ctx.strokeStyle = "rgba(232,230,225,0.7)";
    ctx.lineWidth = 1;
    ctx.stroke();
    ctx.font = "11px 'IBM Plex Mono'";
    ctx.fillStyle = "rgba(232,230,225,0.55)";
    ctx.fillText(p.id, q.x + 6, q.y - 6);
  }
}

function disk(ctx: CanvasRenderingContext2D, x: number, y: number, r: number, fill: string) {
  ctx.beginPath();
  ctx.arc(x, y, r, 0, Math.PI * 2);
  ctx.fillStyle = fill;
  ctx.fill();
}
