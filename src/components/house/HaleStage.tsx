import { useEffect, useRef, useState } from "react";
import type { FilmDef } from "@/hale/theia/films";
import { approachHyperbola, HILL_AU, wanderPath } from "@/hale/theia/paths";

const DURATION = 120;
type Cam = { x: number; y: number; z: number };

const CAMS: Record<FilmDef["mode"], Cam[][]> = {
  wander: [
    [{ x: 0.5, y: 0.86, z: 0.55 }, { x: 0.51, y: 0.87, z: 0.4 }],
    [{ x: 0.48, y: 0.84, z: 0.7 }, { x: 0.52, y: 0.88, z: 0.85 }],
    [{ x: 0.4, y: 0.7, z: 1.4 }, { x: 0.45, y: 0.75, z: 1.2 }],
    [{ x: 0.35, y: 0.55, z: 2.0 }, { x: 0.4, y: 0.6, z: 1.7 }],
    [{ x: 0.25, y: 0.4, z: 2.8 }, { x: 0.3, y: 0.45, z: 2.4 }],
    [{ x: 0.7, y: 0.15, z: 2.2 }, { x: 0.85, y: 0.05, z: 2.0 }],
    [{ x: 0.2, y: 0.3, z: 3.4 }, { x: 0.25, y: 0.35, z: 3.0 }],
    [{ x: 0.18, y: 0.28, z: 3.6 }, { x: 0.2, y: 0.3, z: 3.3 }],
  ],
  hill: [
    [{ x: 0.2, y: 0.15, z: 3.8 }, { x: 0.25, y: 0.2, z: 3.2 }],
    [{ x: 0.85, y: 0.05, z: 1.4 }, { x: 0.95, y: 0.02, z: 1.1 }],
    [{ x: 0.98, y: 0.0, z: 0.35 }, { x: 1.0, y: 0.0, z: 0.22 }],
    [{ x: 0.7, y: 0.4, z: 1.8 }, { x: 0.75, y: 0.45, z: 1.5 }],
    [{ x: 0.9, y: 0.15, z: 0.8 }, { x: 0.95, y: 0.08, z: 0.55 }],
    [{ x: 0.92, y: 0.12, z: 0.7 }, { x: 0.97, y: 0.04, z: 0.45 }],
    [{ x: 0.99, y: 0.0, z: 0.18 }, { x: 1.0, y: 0.0, z: 0.12 }],
    [{ x: 0.3, y: 0.2, z: 3.2 }, { x: 0.35, y: 0.25, z: 2.8 }],
  ],
  hyperbola: [
    [{ x: -40000, y: 25000, z: 90000 }, { x: -30000, y: 18000, z: 70000 }],
    [{ x: -20000, y: 20000, z: 60000 }, { x: -15000, y: 15000, z: 50000 }],
    [{ x: -10000, y: 12000, z: 40000 }, { x: -8000, y: 8000, z: 32000 }],
    [{ x: 0, y: 0, z: 120000 }, { x: 0, y: 0, z: 100000 }],
    [{ x: -5000, y: 8000, z: 28000 }, { x: -2000, y: 5000, z: 20000 }],
    [{ x: 2000, y: 4000, z: 22000 }, { x: 4000, y: 2000, z: 16000 }],
    [{ x: 0, y: 0, z: 50000 }, { x: 2000, y: 1000, z: 40000 }],
    [{ x: 6000, y: 2000, z: 18000 }, { x: 8000, y: 500, z: 14000 }],
  ],
  contact: [
    [{ x: 2000, y: 1800, z: 28000 }, { x: 1500, y: 1200, z: 22000 }],
    [{ x: 0, y: 0, z: 26000 }, { x: 400, y: 200, z: 20000 }],
    [{ x: -2000, y: 0, z: 18000 }, { x: -1000, y: 0, z: 15000 }],
    [{ x: 3000, y: 2500, z: 20000 }, { x: 2500, y: 1800, z: 16000 }],
    [{ x: 1000, y: 3000, z: 17000 }, { x: 800, y: 2200, z: 14000 }],
    [{ x: 0, y: 0, z: 16000 }, { x: 0, y: 0, z: 13000 }],
    [{ x: 4000, y: 500, z: 14000 }, { x: 3500, y: 200, z: 11000 }],
    [{ x: 2200, y: 2200, z: 13000 }, { x: 1800, y: 1600, z: 10500 }],
  ],
};

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

const WANDER = wanderPath();
const HYPER = approachHyperbola();

export function HaleStage({ film, startAt = 0 }: { film: FilmDef; startAt?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);
  const [shotI, setShotI] = useState(0);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d", { alpha: false });
    if (!ctx) return;
    let raf = 0;
    let last = -1;
    const t0 = performance.now() - startAt * 1000;
    const mu = 3.0034806424871e-6;
    const sun = { x: -mu, y: 0 };
    const terraH = { x: 1 - mu, y: 0 };

    const stars = Array.from({ length: 800 }, (_, i) => ({
      a: hash(i) * Math.PI * 2,
      r: 1.2 + hash(i + 3) * 10,
      s: 0.5 + hash(i + 9) * 1.2,
      a0: 0.14 + hash(i + 13) * 0.7,
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
      g.addColorStop(0.45, mid);
      g.addColorStop(1, "#060504");
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(X, Y, Math.max(0.8, R), 0, Math.PI * 2);
      ctx.fill();
    };

    const draw = (now: number) => {
      const t = ((((now - t0) / 1000) % DURATION) + DURATION) % DURATION;
      const i = Math.max(0, Math.min(7, Math.floor(t / 15)));
      if (i !== last) {
        last = i;
        setShotI(i);
      }
      const u = smooth((t - i * 15) / 15);
      const pair = CAMS[film.mode][i]!;
      const cam = {
        x: lerp(pair[0]!.x, pair[1]!.x, u),
        y: lerp(pair[0]!.y, pair[1]!.y, u),
        z: lerp(pair[0]!.z, pair[1]!.z, u),
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
      const band = ctx.createLinearGradient(0, h * 0.34, 0, h * 0.7);
      band.addColorStop(0, "rgba(0,0,0,0)");
      band.addColorStop(0.5, "rgba(70,62,78,0.13)");
      band.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = band;
      ctx.fillRect(0, 0, w, h);
      for (const st of stars) {
        ctx.globalAlpha = st.a0;
        ctx.fillStyle = "#f2eee6";
        ctx.fillRect(w / 2 + Math.cos(st.a) * st.r * (scale * 0.08 + 80), h / 2 + Math.sin(st.a) * st.r * (scale * 0.08 + 80), st.s, st.s);
      }
      ctx.globalAlpha = 1;

      if (film.mode === "wander" || film.mode === "hill") {
        const C = map(0, 0);
        ctx.beginPath();
        ctx.arc(C.X, C.Y, scale, 0, Math.PI * 2);
        ctx.strokeStyle = "rgba(210,200,180,0.07)";
        ctx.stroke();
        const S = map(sun.x, sun.y);
        const glow = ctx.createRadialGradient(S.X, S.Y, 0, S.X, S.Y, Math.max(60, 180 * (0.8 / cam.z)));
        glow.addColorStop(0, "rgba(255,244,210,1)");
        glow.addColorStop(0.12, "rgba(255,200,90,0.45)");
        glow.addColorStop(1, "rgba(255,140,20,0)");
        ctx.fillStyle = glow;
        ctx.beginPath();
        ctx.arc(S.X, S.Y, Math.max(60, 180 * (0.8 / cam.z)), 0, Math.PI * 2);
        ctx.fill();
        const T = map(terraH.x, terraH.y);
        const terraR = Math.max(3, 8 * (0.5 / Math.max(0.2, cam.z)));
        body(T.X, T.Y, terraR, S.X, S.Y, "#4f86b8", "#d7e8f8");

        if (film.mode === "wander") {
          ctx.beginPath();
          WANDER.points.forEach((p, k) => {
            const m = map(p.x, p.y);
            if (k === 0) ctx.moveTo(m.X, m.Y);
            else ctx.lineTo(m.X, m.Y);
          });
          ctx.strokeStyle = "rgba(200,140,90,0.45)";
          ctx.lineWidth = 1.4;
          ctx.stroke();
          const prog = Math.min(WANDER.points.length - 1, Math.floor((t / DURATION) * WANDER.points.length));
          const p = WANDER.points[prog]!;
          const Th = map(p.x, p.y);
          body(Th.X, Th.Y, Math.max(2, terraR * 0.72), S.X, S.Y, "#7a3f2a", "#d9a06a");
          const L = map(WANDER.L4.x, WANDER.L4.y);
          ctx.strokeStyle = "rgba(236,232,225,0.25)";
          ctx.beginPath();
          ctx.arc(L.X, L.Y, 5, 0, Math.PI * 2);
          ctx.stroke();
        } else {
          ctx.beginPath();
          ctx.arc(T.X, T.Y, HILL_AU * scale, 0, Math.PI * 2);
          ctx.strokeStyle = "rgba(180,200,220,0.28)";
          ctx.setLineDash([5, 6]);
          ctx.stroke();
          ctx.setLineDash([]);
          const ang = -0.35 + (t / DURATION) * 0.7;
          const rTheia = HILL_AU * (1.55 - 0.7 * (t / DURATION));
          const Th = map(terraH.x + Math.cos(ang) * rTheia, terraH.y + Math.sin(ang) * rTheia);
          body(Th.X, Th.Y, Math.max(2, terraR * 0.7), S.X, S.Y, "#7a3f2a", "#d9a06a");
        }
      }

      if (film.mode === "hyperbola" || film.mode === "contact") {
        ctx.beginPath();
        HYPER.points.forEach((p, k) => {
          const m = map(p.x, p.y);
          if (k === 0) ctx.moveTo(m.X, m.Y);
          else ctx.lineTo(m.X, m.Y);
        });
        ctx.strokeStyle = "rgba(200,150,100,0.4)";
        ctx.lineWidth = 1.3;
        ctx.stroke();
        const T = map(0, 0);
        const sunX = T.X - 200;
        const terraR = film.mode === "contact" ? Math.max(8, 28 * (8000 / cam.z)) : Math.max(3, 8 * (20000 / cam.z));
        const theiaR = terraR * 0.53;
        body(T.X, T.Y, terraR, sunX, T.Y, "#4f86b8", "#d7e8f8");
        const prog = Math.min(HYPER.points.length - 1, Math.floor((t / DURATION) * HYPER.points.length));
        const p = HYPER.points[prog]!;
        const Th = map(p.x, p.y);
        body(Th.X, Th.Y, theiaR, sunX, T.Y, "#7a3f2a", "#d9a06a");
      }

      const vig = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * 0.3, w / 2, h / 2, Math.max(w, h) * 0.72);
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
  }, [film.mode, startAt]);

  const s = film.shots[shotI]!;
  return (
    <div className="relative overflow-hidden rounded-xl bg-house">
      <canvas ref={ref} className="aspect-video w-full" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 px-5 pb-4 pt-16">
        <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
          {s.tStart} · {s.title} · 4K UHD 3840×2160
        </p>
        <p className="font-mono text-xs text-house-mute">{s.finding}</p>
      </div>
    </div>
  );
}
