import { useEffect, useRef, useState } from "react";
import { EP01, EP01_SHOTS } from "@/hale/theia/ep01-film";

const DURATION = 120;

type Cam = { x: number; y: number; z: number };
const SHOTS: Array<{ cam0: Cam; cam1: Cam; inertial: boolean }> = [
  { cam0: { x: 0.28, y: 0.32, z: 3.6 }, cam1: { x: 0.4, y: 0.46, z: 2.4 }, inertial: false },
  { cam0: { x: 0.46, y: 0.8, z: 0.95 }, cam1: { x: 0.5, y: 0.866, z: 0.38 }, inertial: false },
  { cam0: { x: 0.58, y: 0.78, z: 0.62 }, cam1: { x: 0.72, y: 0.55, z: 0.9 }, inertial: false },
  { cam0: { x: 0.78, y: 0.38, z: 1.35 }, cam1: { x: 0.9, y: 0.18, z: 1.7 }, inertial: false },
  { cam0: { x: 0.12, y: 0.08, z: 4.1 }, cam1: { x: 0.08, y: 0.04, z: 3.4 }, inertial: true },
  { cam0: { x: 0.5, y: 0.866, z: 0.18 }, cam1: { x: 0.505, y: 0.86, z: 0.12 }, inertial: false },
  { cam0: { x: 0.22, y: 0.48, z: 2.35 }, cam1: { x: 0.26, y: 0.52, z: 2.05 }, inertial: false },
  { cam0: { x: 0.18, y: 0.28, z: 3.8 }, cam1: { x: 0.22, y: 0.32, z: 3.3 }, inertial: false },
];

function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t;
}
function smooth(t: number) {
  return t * t * (3 - 2 * t);
}

function hash(i: number) {
  const x = Math.sin(i * 127.1 + 311.7) * 43758.5453;
  return x - Math.floor(x);
}

export function TrojanFilm({ startAt = 0 }: { startAt?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const [shotI, setShotI] = useState(0);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d", { alpha: false });
    if (!ctx) return;

    let raf = 0;
    let lastShot = -1;
    const t0 = performance.now() - startAt * 1000;
    const mu = 3.0034806424871e-6;
    const sun = { x: -mu, y: 0 };
    const terra = { x: 1 - mu, y: 0 };
    const theia = { x: EP01.numbers.x, y: EP01.numbers.y };

    const stars = Array.from({ length: 900 }, (_, i) => ({
      a: hash(i) * Math.PI * 2,
      r: 1.4 + hash(i + 3) * 9,
      s: hash(i + 7) < 0.92 ? 0.5 + hash(i + 9) * 1.1 : 1.6 + hash(i + 11),
      a0: 0.15 + hash(i + 13) * 0.75,
    }));

    const dust = Array.from({ length: 280 }, (_, i) => ({
      a: hash(i + 40) * Math.PI * 2,
      w: 0.92 + hash(i + 41) * 0.16,
      s: 0.6 + hash(i + 42) * 1.4,
    }));

    const fit = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 3);
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      canvas.width = Math.round(w * dpr);
      canvas.height = Math.round(h * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    fit();
    const ro = new ResizeObserver(fit);
    ro.observe(canvas);

    const body = (
      X: number,
      Y: number,
      R: number,
      sunX: number,
      sunY: number,
      mid: string,
      hi: string,
    ) => {
      const ang = Math.atan2(Y - sunY, X - sunX);
      const hx = X - Math.cos(ang) * R * 0.38;
      const hy = Y - Math.sin(ang) * R * 0.38;
      const g = ctx.createRadialGradient(hx, hy, R * 0.08, X, Y, R);
      g.addColorStop(0, hi);
      g.addColorStop(0.42, mid);
      g.addColorStop(1, "#060504");
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(X, Y, R, 0, Math.PI * 2);
      ctx.fill();
    };

    const draw = (now: number) => {
      const raw = (now - t0) / 1000;
      const t = ((raw % DURATION) + DURATION) % DURATION;
      const i = Math.max(0, Math.min(7, Math.floor(t / 15)));
      if (i !== lastShot) {
        lastShot = i;
        setShotI(i);
      }
      const u = smooth((t - i * 15) / 15);
      const shot = SHOTS[i]!;
      const cam = {
        x: lerp(shot.cam0.x, shot.cam1.x, u),
        y: lerp(shot.cam0.y, shot.cam1.y, u),
        z: lerp(shot.cam0.z, shot.cam1.z, u),
      };
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      if (w < 2 || h < 2) {
        raf = requestAnimationFrame(draw);
        return;
      }
      const scale = Math.min(w, h) / cam.z;
      const rot = shot.inertial ? t * 0.045 : 0;

      const map = (x: number, y: number) => {
        const dx = x - cam.x;
        const dy = y - cam.y;
        const c = Math.cos(rot);
        const s = Math.sin(rot);
        return { X: w / 2 + (dx * c - dy * s) * scale, Y: h / 2 + (dx * s + dy * c) * scale };
      };

      ctx.fillStyle = "#050508";
      ctx.fillRect(0, 0, w, h);

      const band = ctx.createLinearGradient(0, h * 0.35, 0, h * 0.72);
      band.addColorStop(0, "rgba(0,0,0,0)");
      band.addColorStop(0.5, "rgba(70,62,78,0.16)");
      band.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = band;
      ctx.fillRect(0, 0, w, h);

      for (const st of stars) {
        const sx = w / 2 + Math.cos(st.a + rot * 0.12) * st.r * scale * 0.32;
        const sy = h / 2 + Math.sin(st.a + rot * 0.12) * st.r * scale * 0.32;
        ctx.globalAlpha = st.a0;
        ctx.fillStyle = "#f2eee6";
        ctx.fillRect(sx, sy, st.s, st.s);
      }
      ctx.globalAlpha = 1;

      const C = map(0, 0);
      ctx.beginPath();
      ctx.arc(C.X, C.Y, scale, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(210,200,180,0.07)";
      ctx.lineWidth = 1.25;
      ctx.stroke();

      for (const d of dust) {
        const p = map(Math.cos(d.a) * d.w, Math.sin(d.a) * d.w);
        ctx.globalAlpha = 0.08;
        ctx.fillStyle = "#d8c8a8";
        ctx.fillRect(p.X, p.Y, d.s, d.s);
      }
      ctx.globalAlpha = 1;

      const S = map(sun.x, sun.y);
      const corona = Math.max(70, 220 * (0.7 / cam.z));
      const glow = ctx.createRadialGradient(S.X, S.Y, 0, S.X, S.Y, corona);
      glow.addColorStop(0, "rgba(255,244,210,1)");
      glow.addColorStop(0.08, "rgba(255,214,120,0.75)");
      glow.addColorStop(0.28, "rgba(255,170,60,0.22)");
      glow.addColorStop(1, "rgba(255,140,20,0)");
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(S.X, S.Y, corona, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#fff8e4";
      ctx.beginPath();
      ctx.arc(S.X, S.Y, Math.max(3.5, 9 * (0.45 / cam.z)), 0, Math.PI * 2);
      ctx.fill();

      const T = map(terra.x, terra.y);
      const Th = map(theia.x, theia.y);
      const terraR = Math.max(3.4, 8.4 * (0.5 / cam.z));
      const theiaR = Math.max(2.6, 6.2 * (0.5 / cam.z));

      body(T.X, T.Y, terraR, S.X, S.Y, "#4f86b8", "#d7e8f8");
      ctx.strokeStyle = "rgba(150,200,255,0.35)";
      ctx.lineWidth = Math.max(1.2, terraR * 0.18);
      ctx.beginPath();
      ctx.arc(T.X, T.Y, terraR + ctx.lineWidth * 0.4, 0, Math.PI * 2);
      ctx.stroke();

      body(Th.X, Th.Y, theiaR, S.X, S.Y, "#7a3f2a", "#d9a06a");

      const vig = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * 0.28, w / 2, h / 2, Math.max(w, h) * 0.72);
      vig.addColorStop(0, "rgba(0,0,0,0)");
      vig.addColorStop(1, "rgba(0,0,0,0.55)");
      ctx.fillStyle = vig;
      ctx.fillRect(0, 0, w, h);

      raf = requestAnimationFrame(draw);
    };
    raf = requestAnimationFrame(draw);
    return () => {
      cancelAnimationFrame(raf);
      ro.disconnect();
    };
  }, [startAt]);

  const s = EP01_SHOTS[shotI]!;

  return (
    <div className="relative overflow-hidden rounded-xl bg-house">
      <canvas ref={ref} className="aspect-video w-full" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 px-5 pb-4 pt-16">
        <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
          {s.tStart} · {s.title} · {EP01.delivery}
        </p>
        <p className="font-mono text-xs text-house-mute">{s.finding}</p>
      </div>
    </div>
  );
}
