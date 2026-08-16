import { useEffect, useRef, useState } from "react";
import { EP01, EP01_SHOTS } from "@/hale/theia/ep01-film";

const CLIPS = EP01_SHOTS.map((s) => s.file);
const MASTER = "/films/003/the-trojan-twin-4k.mp4";

export function TheiaPlayer() {
  const video = useRef<HTMLVideoElement>(null);
  const [on, setOn] = useState(0);
  const [masterOk, setMasterOk] = useState(true);

  useEffect(() => {
    const el = video.current;
    if (!el) return;
    void el.play().catch(() => undefined);
  }, [on, masterOk]);

  const src = masterOk ? MASTER : CLIPS[on]!;
  const shot = EP01_SHOTS[on]!;

  return (
    <div className="relative overflow-hidden rounded-xl bg-house">
      <video
        ref={video}
        key={src}
        className="aspect-video w-full bg-house object-cover"
        src={src}
        poster={shot.still}
        muted
        playsInline
        autoPlay
        controls={!masterOk}
        onError={() => {
          if (masterOk) setMasterOk(false);
          else setOn((i) => (i + 1) % CLIPS.length);
        }}
        onEnded={() => {
          if (masterOk) {
            const el = video.current;
            if (el) {
              el.currentTime = 0;
              void el.play().catch(() => undefined);
            }
          } else setOn((i) => (i + 1) % CLIPS.length);
        }}
        onTimeUpdate={() => {
          if (!masterOk) return;
          const el = video.current;
          if (!el) return;
          setOn(Math.min(7, Math.floor(el.currentTime / 15)));
        }}
      />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 px-5 pb-4 pt-16">
        <p className="font-house text-xs tracking-[0.18em] text-house-mute uppercase">
          {shot.tStart} · {shot.title} · {EP01.delivery}
        </p>
        <p className="font-mono text-xs text-house-mute">{shot.finding}</p>
      </div>
    </div>
  );
}
