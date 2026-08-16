import { useEffect, useRef, useState } from "react";
import { EP02, EP02_SHOTS } from "@/hale/theia/ep02-film";
import { EP01 } from "@/hale/theia/ep01-film";

const DURATION = 120;

type Cam = { x: number; y: number; z: number };
const SHOTS: Array<{ cam0: Cam; cam1: Cam }> = [
  { cam0: { x: 0.32, y: 0.38, z: 3.5 }, cam1: { x: 0.4, y: 0.48, z: 2.7 } },
  { cam0: { x: 0.48, y: 0.82, z: 0.9 }, cam1: { x: 0.5, y: 0.866, z: 0.42 } },
  { cam0: { x: 0.5, y: 0.86, z: 0.55 }, cam1: { x: 0.52, y: 0.84, z: 0.48 } },
  { cam0: { x: 0.38, y: 0.5, z: 2.2 }, cam1: { x: 0.42, y: 0.55, z: 1.8 } },
  { cam0: { x: 0.2, y: 0.25, z: 3.8 }, cam1: { x: 0.22, y: 0.3, z: 3.2 } },
  { cam0: { x: 0.45, y: 0.7, z: 1.5 }, cam1: { x: 0.5, y: 0.8, z: 1.15 } },
  { cam0: { x: 0.5, y: 0.866, z: 0.28 }, cam1: { x: 0.5, y: 0.86, z: 0.2 } },
  { cam0: { x: 0.18, y: 0.28, z: 3.7 }, cam1: { x: 0.22, y: 0.34, z: 3.2 } },
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

/** Visual mass 0→1 over the film. Crosses Routh at ~0.42 of the growth. */
function growth(t: number) {
  return smooth(Math.min(1, t / DURATION));
}

export function TenPercentFilm({ startAt = 0 }: { startAt?: number }) {
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
      s: hash(i + 7) < 0.92 ? 0.5 + hash(i + 9) * 1.1 : 1.6,
      a0: 0.15 + hash(i + 13) * 0.75,
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

    const body = (X: number, Y: number, R: number, sX: number, sY: number, mid: string, hi: string) => {
      const ang = Math.atan2(Y - sY, X - sX);
      const g = ctx.createRadialGradient(
        X - Math.cos(ang) * R * 0.38,
        Y - Math.sin(ang) * R * 0.38,
        R * 0.08,
        X,
        Y,
        R,
      );
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
      const map = (x: number, y: number) => ({
        X: w / 2 + (x - cam.x) * scale,
        Y: h / 2 + (y - cam.y) * scale,
      });

      ctx.fillStyle = "#050508";
      ctx.fillRect(0, 0, w, h);
      const band = ctx.createLinearGradient(0, h * 0.35, 0, h * 0.72);
      band.addColorStop(0, "rgba(0,0,0,0)");
      band.addColorStop(0.5, "rgba(70,62,78,0.14)");
      band.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = band;
      ctx.fillRect(0, 0, w, h);

      for (const st of stars) {
        ctx.globalAlpha = st.a0;
        ctx.fillStyle = "#f2eee6";
        ctx.fillRect(
          w / 2 + Math.cos(st.a) * st.r * scale * 0.32,
          h / 2 + Math.sin(st.a) * st.r * scale * 0.32,
          st.s,
          st.s,
        );
      }
      ctx.globalAlpha = 1;

      const C = map(0, 0);
      ctx.beginPath();
      ctx.arc(C.X, C.Y, scale, 0, Math.PI * 2);
      ctx.strokeStyle = "rgba(210,200,180,0.07)";
      ctx.stroke();

      const S = map(sun.x, sun.y);
      const corona = Math.max(70, 200 * (0.7 / cam.z));
      const glow = ctx.createRadialGradient(S.X, S.Y, 0, S.X, S.Y, corona);
      glow.addColorStop(0, "rgba(255,244,210,1)");
      glow.addColorStop(0.1, "rgba(255,214,120,0.7)");
      glow.addColorStop(1, "rgba(255,140,20,0)");
      ctx.fillStyle = glow;
      ctx.beginPath();
      ctx.arc(S.X, S.Y, corona, 0, Math.PI * 2);
      ctx.fill();

      const T = map(terra.x, terra.y);
      const Th = map(theia.x, theia.y);
      const g = growth(t);
      const terraR = Math.max(3.4, 8.4 * (0.5 / cam.z));
      const theiaR = Math.max(0.7, (1.1 + g * 5.4) * (0.5 / cam.z));

      body(T.X, T.Y, terraR, S.X, S.Y, "#4f86b8", "#d7e8f8");
      ctx.strokeStyle = "rgba(150,200,255,0.32)";
      ctx.lineWidth = Math.max(1, terraR * 0.16);
      ctx.beginPath();
      ctx.arc(T.X, T.Y, terraR + ctx.lineWidth * 0.35, 0, Math.PI * 2);
      ctx.stroke();

      body(Th.X, Th.Y, theiaR, S.X, S.Y, "#7a3f2a", "#d9a06a");

      // faint debris falling into Theia as it grows
      const fall = 18 + Math.floor(g * 40);
      ctx.fillStyle = "#c4a080";
      for (let k = 0; k < fall; k++) {
        const a = hash(k + 90) * Math.PI * 2;
        const rad = theiaR * (1.6 + hash(k + 91) * 3.2) * (1 - g * 0.35);
        ctx.globalAlpha = 0.15 + hash(k + 92) * 0.25;
        ctx.fillRect(Th.X + Math.cos(a + t * 0.04) * rad, Th.Y + Math.sin(a + t * 0.04) * rad, 1.2, 1.2);
      }
      ctx.globalAlpha = 1;

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

  const s = EP02_SHOTS[shotI]!;
  return (
    <div className="relative overflow-hidden rounded-xl bg-house">
      <canvas ref={ref} className="aspect-video w-full" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 px-5 pb-4 pt-16">
        <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
          {s.tStart} · {s.title} · {EP02.delivery}
        </p>
        <p className="font-mono text-xs text-house-mute">{s.finding}</p>
      </div>
    </div>
  );
}
