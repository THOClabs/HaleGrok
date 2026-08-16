import { useEffect, useRef } from "react";

const DURATION = 40;
const RE = 6378;
const RT = 3396;
const CONTACT = 12;

function lerp(a: number, b: number, t: number) {
  return a + (b - a) * t;
}
function smooth(t: number) {
  const x = Math.max(0, Math.min(1, t));
  return x * x * (3 - 2 * x);
}
function hash(i: number) {
  const x = Math.sin(i * 127.1 + 311.7) * 43758.5453;
  return x - Math.floor(x);
}

type Cam = { x: number; y: number; z: number };

function camera(t: number): Cam {
  if (t < 12) {
    const u = smooth(t / 12);
    return { x: lerp(8000, 2500, u), y: lerp(6000, 2800, u), z: lerp(52000, 20000, u) };
  }
  if (t < 18) {
    const u = smooth((t - 12) / 6);
    return { x: lerp(2500, 1800, u), y: lerp(2800, 1600, u), z: lerp(20000, 16000, u) };
  }
  if (t < 28) {
    const u = smooth((t - 18) / 10);
    return { x: lerp(1800, 4000, u), y: lerp(1600, 2500, u), z: lerp(16000, 42000, u) };
  }
  const u = smooth((t - 28) / 12);
  return { x: lerp(4000, 12000, u), y: lerp(2500, 4000, u), z: lerp(42000, 88000, u) };
}

export function ImpactFilm({ startAt = 0 }: { startAt?: number }) {
  const ref = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = ref.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d", { alpha: false });
    if (!ctx) return;
    let raf = 0;
    const t0 = performance.now() - startAt * 1000;

    const stars = Array.from({ length: 900 }, (_, i) => ({
      a: hash(i) * Math.PI * 2,
      r: 80 + hash(i + 2) * 1400,
      s: 0.5 + hash(i + 5) * 1.4,
      a0: 0.12 + hash(i + 8) * 0.75,
    }));

    const debris = Array.from({ length: 900 }, (_, i) => {
      const cone = Math.PI / 4 + (hash(i) - 0.5) * 1.6;
      return {
        a0: cone,
        r0: RE * (0.95 + hash(i + 1) * 0.25),
        vr: 4 + hash(i + 4) * 14,
        va: 0.15 + hash(i + 9) * 0.4,
        size: 1.2 + hash(i + 11) * 3.8,
        hot: hash(i + 13),
        streak: 8 + hash(i + 17) * 22,
      };
    });

    const fit = () => {
      const dpr = Math.min(window.devicePixelRatio || 1, 2);
      canvas.width = Math.round(canvas.clientWidth * dpr);
      canvas.height = Math.round(canvas.clientHeight * dpr);
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };
    fit();
    const ro = new ResizeObserver(fit);
    ro.observe(canvas);

    const sphere = (X: number, Y: number, R: number, mid: string, hi: string, melt: number) => {
      const g = ctx.createRadialGradient(X - R * 0.35, Y - R * 0.35, R * 0.08, X, Y, R);
      g.addColorStop(0, hi);
      g.addColorStop(0.42, mid);
      g.addColorStop(0.78, melt > 0.4 ? "#4a1c0c" : "#070605");
      g.addColorStop(1, "#030201");
      ctx.fillStyle = g;
      ctx.beginPath();
      ctx.arc(X, Y, Math.max(1, R), 0, Math.PI * 2);
      ctx.fill();
      if (melt > 0.15) {
        const crack = ctx.createRadialGradient(X + R * 0.2, Y, 0, X, Y, R);
        crack.addColorStop(0, `rgba(255,160,60,${0.18 + melt * 0.35})`);
        crack.addColorStop(1, "rgba(255,80,10,0)");
        ctx.fillStyle = crack;
        ctx.beginPath();
        ctx.arc(X, Y, R, 0, Math.PI * 2);
        ctx.fill();
      }
    };

    const draw = (now: number) => {
      const t = ((((now - t0) / 1000) % DURATION) + DURATION) % DURATION;
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      if (w < 2) {
        raf = requestAnimationFrame(draw);
        return;
      }
      const cam = camera(t);
      const scale = Math.min(w, h) / cam.z;
      const map = (x: number, y: number) => ({
        X: w / 2 + (x - cam.x) * scale,
        Y: h / 2 + (y - cam.y) * scale,
      });

      ctx.fillStyle = "#030308";
      ctx.fillRect(0, 0, w, h);
      const haze = ctx.createRadialGradient(w * 0.35, h * 0.4, 0, w * 0.4, h * 0.45, Math.max(w, h) * 0.7);
      haze.addColorStop(0, "rgba(40,28,50,0.18)");
      haze.addColorStop(1, "rgba(0,0,0,0)");
      ctx.fillStyle = haze;
      ctx.fillRect(0, 0, w, h);

      for (const st of stars) {
        ctx.globalAlpha = st.a0;
        ctx.fillStyle = "#f4f0e8";
        ctx.fillRect(w / 2 + Math.cos(st.a) * st.r, h / 2 + Math.sin(st.a) * st.r * 0.62, st.s, st.s);
      }
      ctx.globalAlpha = 1;

      const sunX = w * 0.12;
      const sunY = h * 0.22;
      const sunG = ctx.createRadialGradient(sunX, sunY, 0, sunX, sunY, 220);
      sunG.addColorStop(0, "rgba(255,244,210,0.95)");
      sunG.addColorStop(0.12, "rgba(255,190,80,0.35)");
      sunG.addColorStop(1, "rgba(255,120,20,0)");
      ctx.fillStyle = sunG;
      ctx.beginPath();
      ctx.arc(sunX, sunY, 220, 0, Math.PI * 2);
      ctx.fill();

      const hit = Math.max(0, t - CONTACT);
      const melt = smooth(Math.min(1, hit / 4));
      const terra = map(0, 0);
      const terraR = RE * scale;

      const uIn = Math.min(1, t / CONTACT);
      const dist = lerp(42000, 9774, smooth(uIn));
      const ang = Math.PI / 4;
      const thx = Math.cos(ang) * dist;
      const thy = Math.sin(ang) * dist;

      if (t < CONTACT + 0.35) {
        const Th = map(thx, thy);
        sphere(Th.X, Th.Y, RT * scale, "#7a3f2a", "#e0b07a", t > CONTACT - 0.4 ? 0.6 : 0);
      }

      sphere(terra.X, terra.Y, terraR, melt > 0.3 ? "#6a3a28" : "#4f86b8", melt > 0.3 ? "#ffb060" : "#d7e8f8", melt);

      if (hit > 0) {
        const flash = Math.exp(-hit * 1.6);
        ctx.fillStyle = `rgba(255,230,190,${flash * 0.72})`;
        ctx.fillRect(0, 0, w, h);
        const ring = map(Math.cos(ang) * RE * 0.7, Math.sin(ang) * RE * 0.7);
        ctx.strokeStyle = `rgba(255,200,120,${0.55 * flash})`;
        ctx.lineWidth = 3 + 10 * flash;
        ctx.beginPath();
        ctx.arc(ring.X, ring.Y, (2000 + hit * 9000) * scale, 0, Math.PI * 2);
        ctx.stroke();
      }

      if (hit > 0.05) {
        const age = hit;
        for (const d of debris) {
          const r = d.r0 + d.vr * age * 1100;
          const a = d.a0 + d.va * age * 0.18;
          const p = map(Math.cos(a) * r, Math.sin(a) * r);
          const fade = Math.min(1, age / 1.2) * (1 - Math.min(0.6, r / 110000));
          ctx.globalAlpha = 0.2 + fade * 0.75;
          ctx.strokeStyle = d.hot > 0.4 ? "#ffc070" : "#d4a078";
          ctx.lineWidth = Math.max(1, d.size * scale * 80);
          const back = map(Math.cos(a) * (r - d.streak * age * 80), Math.sin(a) * (r - d.streak * age * 80));
          ctx.beginPath();
          ctx.moveTo(back.X, back.Y);
          ctx.lineTo(p.X, p.Y);
          ctx.stroke();
        }
        ctx.globalAlpha = 1;

        ctx.beginPath();
        ctx.ellipse(terra.X, terra.Y, RE * 4.2 * scale, RE * 1.15 * scale, 0.35, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(255,170,80,${0.12 + 0.2 * Math.min(1, age / 8)})`;
        ctx.stroke();
      }

      if (t > 26) {
        const grow = smooth((t - 26) / 10);
        const lr = lerp(RE * 2.2, RE * 5.4, grow);
        const la = 0.4 + (t - 26) * 0.08;
        const L = map(Math.cos(la) * lr, Math.sin(la) * lr);
        sphere(L.X, L.Y, lerp(200, 1737, grow) * scale, "#b8b0a4", "#ffe8c8", 0.7 * (1 - grow * 0.4));
      }

      const vig = ctx.createRadialGradient(w / 2, h / 2, Math.min(w, h) * 0.25, w / 2, h / 2, Math.max(w, h) * 0.72);
      vig.addColorStop(0, "rgba(0,0,0,0)");
      vig.addColorStop(1, "rgba(0,0,0,0.62)");
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

  return <canvas ref={ref} className="h-full w-full bg-house" />;
}
