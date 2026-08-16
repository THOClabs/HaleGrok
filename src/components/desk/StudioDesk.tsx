import { SignedIn, SignedOut, UserButton } from "@/lib/auth/gates";
import { signIn } from "@/lib/auth/client";
import { CATALOG, FAMILY_LABEL } from "@/hale/catalog";
import { GATE_ORDER } from "@/hale/types";
import { isRunnable, slateForRound } from "@/hale/slate";
import { commissionFor } from "@/hale/commissions";
import { xComposeUrl, xProfileUrl } from "@/hale/x-compose";
import { useDesk } from "@/store/desk";
import { Button } from "@/components/ui/button";
import { OrbitPlot } from "./OrbitPlot";
import { FilmReel } from "./FilmReel";
import { cn } from "@/lib/utils";
import { Check, Circle, Lock, Play, X as XIcon, Clapperboard } from "lucide-react";

const SLATE = slateForRound(1);

export function StudioDesk() {
  const { selectedId, select, runSelected, result, reviews, running, approved, approve, liked, likeThis } =
    useDesk();
  const production = CATALOG.find((p) => p.id === selectedId) ?? CATALOG[0]!;
  const runnable = isRunnable(production);
  const done = Boolean(approved[production.id]);
  const weLike = Boolean(liked[production.id] || commissionFor(production.id));
  const reviewPass = result?.gates.find((g) => g.id === "REVIEW")?.status === "pass";
  const commission = commissionFor(production.id);

  return (
    <div className="flex min-h-dvh flex-col bg-bg text-fg">
      <header className="flex items-center justify-between gap-6 border-b border-line px-5 py-3">
        <div className="flex items-baseline gap-4">
          <h1 className="font-sans text-lg font-semibold tracking-tight">HaleGrok</h1>
          <p className="hidden text-sm text-muted md:block">
            Code sim → we both like it → long 4K → Approve → X
          </p>
        </div>
        <div className="flex items-center gap-4">
          <a
            href={xProfileUrl()}
            target="_blank"
            rel="noreferrer"
            className="hidden font-mono text-xs text-muted hover:text-fg sm:inline"
          >
            @{`thenlaguna`}
          </a>
          <SignedOut>
            <Button size="sm" variant="outline" onClick={() => void signIn("grok-x")}>
              Sign in with X
            </Button>
          </SignedOut>
          <SignedIn>
            <UserButton />
          </SignedIn>
        </div>
      </header>

      <section className="border-b border-line px-5 py-4">
        <div className="mb-3 flex items-end justify-between gap-4">
          <div>
            <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
              Round 1 slate · eight films
            </p>
            <h2 className="text-xl font-medium tracking-tight">This week’s offering</h2>
          </div>
          <p className="max-w-md text-right text-sm text-muted">
            Each card is a Hale script. We watch the numbers. If we both like
            the sim, we commission a long 4K film — clip by clip, together.
          </p>
        </div>
        <div className="grid grid-cols-2 gap-2 md:grid-cols-4 xl:grid-cols-8">
          {SLATE.map((p) => {
            const on = p.id === selectedId;
            return (
              <button
                key={p.id}
                type="button"
                onClick={() => select(p.id)}
                className={cn(
                  "min-h-24 rounded-md border px-3 py-3 text-left transition-colors",
                  on ? "border-accent bg-raised" : "border-line bg-surface hover:border-muted",
                )}
              >
                <div className="mb-2 flex items-center justify-between gap-2">
                  <span className="font-mono text-[11px] text-muted">
                    {String(p.id).padStart(3, "0")}
                  </span>
                  <span
                    className="h-2 w-2 rounded-full"
                    style={{ background: p.storyboard.colorHex }}
                  />
                </div>
                <div className="text-sm font-medium leading-tight">{p.title}</div>
                <div className="mt-1 font-mono text-[10px] uppercase tracking-wider text-faint">
                  {FAMILY_LABEL[p.family]}
                </div>
              </button>
            );
          })}
        </div>
      </section>

      <div className="grid flex-1 grid-cols-1 lg:grid-cols-[220px_minmax(0,1fr)_340px]">
        <aside className="desk-scroll max-h-[52vh] overflow-y-auto border-b border-line lg:max-h-none lg:border-b-0 lg:border-r">
          <p className="sticky top-0 bg-bg px-4 py-3 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
            100 productions
          </p>
          <ul>
            {CATALOG.map((p) => {
              const on = p.id === selectedId;
              const live = isRunnable(p);
              return (
                <li key={p.id}>
                  <button
                    type="button"
                    onClick={() => select(p.id)}
                    className={cn(
                      "flex w-full items-center gap-2 px-4 py-2 text-left text-sm",
                      on ? "bg-raised text-fg" : "text-muted hover:bg-surface hover:text-fg",
                    )}
                  >
                    <span className="w-8 font-mono text-[11px] text-faint">
                      {String(p.id).padStart(3, "0")}
                    </span>
                    <span className="flex-1 truncate">{p.title}</span>
                    {live ? (
                      <Circle className="h-2 w-2 fill-accent text-accent" />
                    ) : (
                      <Lock className="h-3 w-3 text-faint" />
                    )}
                  </button>
                </li>
              );
            })}
          </ul>
        </aside>

        <main className="flex min-h-0 flex-col">
          <div className="flex flex-wrap items-start justify-between gap-4 border-b border-line px-5 py-4">
            <div className="max-w-2xl">
              <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted">
                {FAMILY_LABEL[production.family]} · {production.haleRef}
              </p>
              <h2 className="mt-1 text-3xl font-semibold tracking-tight">{production.title}</h2>
              <p className="mt-2 text-sm text-muted">{production.synopsis}</p>
              <p className="mt-2 text-sm">
                <span className="text-muted">Astronaut event — </span>
                {production.storyboard.astronaut}
              </p>
            </div>
            <div className="flex flex-col items-end gap-2">
              <Button size="lg" onClick={() => runSelected()} disabled={!runnable || running}>
                <Play className="h-4 w-4" />
                {running ? "Running…" : "Run Hale script"}
              </Button>
              <p className="font-mono text-[11px] text-faint">{production.adaRef}</p>
            </div>
          </div>

          <div className="min-h-80 flex-1">
            <OrbitPlot
              plot={
                result?.plot ?? {
                  kind: production.family === "cr3bp" ? "cr3bp" : "hohmann",
                  colorHex: production.storyboard.colorHex,
                }
              }
              title={
                result
                  ? `${production.storyboard.colorName} · live from the script`
                  : `${production.storyboard.colorName} · waiting on the script`
              }
            />
          </div>

          <FilmReel productionId={production.id} />

          <div className="desk-scroll max-h-56 overflow-auto border-t border-line">
            <table className="w-full text-left text-sm">
              <thead className="sticky top-0 bg-surface font-mono text-[11px] uppercase tracking-wider text-muted">
                <tr>
                  <th className="px-4 py-2 font-medium">Step</th>
                  <th className="px-4 py-2 font-medium">Ada / Hale</th>
                  <th className="px-4 py-2 font-medium">Finding</th>
                </tr>
              </thead>
              <tbody>
                {(result?.steps ?? []).map((s) => (
                  <tr key={s.name} className="border-t border-line">
                    <td className="px-4 py-2">
                      <span className={s.ok ? "text-pass" : "text-fail"}>{s.name}</span>
                    </td>
                    <td className="px-4 py-2 font-mono text-xs text-muted">{s.source}</td>
                    <td className="px-4 py-2 text-muted">{s.detail}</td>
                  </tr>
                ))}
                {!result && (
                  <tr>
                    <td colSpan={3} className="px-4 py-8 text-center text-muted">
                      Run the Hale script. The picture is not allowed to exist before the
                      findings.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </main>

        <aside className="desk-scroll flex flex-col gap-0 border-t border-line lg:border-l lg:border-t-0">
          <Block title="Storyboard">
            <p className="text-sm italic text-fg">{production.storyboard.logline}</p>
            <div className="mt-3 flex items-center gap-2 text-xs">
              <span
                className="inline-block h-3 w-3 rounded-sm"
                style={{ background: production.storyboard.colorHex }}
              />
              <span className="text-muted">{production.storyboard.colorName}</span>
            </div>
            <ol className="mt-3 space-y-2">
              {(result?.storyboard ?? production.storyboard).beats.map((b) => (
                <li key={b.t} className="text-sm">
                  <span className="font-mono text-[11px] text-accent">{b.t}</span>{" "}
                  <span>{b.shot}</span>
                  <div className="font-mono text-[11px] text-faint">{b.fromFinding}</div>
                </li>
              ))}
            </ol>
          </Block>

          <Block title="Gauntlet">
            <ul className="space-y-1">
              {GATE_ORDER.map((id) => {
                const g = result?.gates.find((x) => x.id === id);
                const status = g?.status ?? "idle";
                return (
                  <li key={id} className="flex items-start gap-2 font-mono text-[11px]">
                    <span
                      className={cn(
                        "mt-0.5 w-14 uppercase",
                        status === "pass" && "text-pass",
                        status === "fail" && "text-fail",
                        status === "locked" && "text-faint",
                        status === "idle" && "text-muted",
                      )}
                    >
                      {id}
                    </span>
                    <span className="text-muted">{g?.detail ?? "—"}</span>
                  </li>
                );
              })}
            </ul>
          </Block>

          <Block title="Review room">
            {reviews.length === 0 ? (
              <p className="text-sm text-muted">
                Vallado, Hopper, Murch, and Sagan read the findings after the script runs.
              </p>
            ) : (
              <ul className="space-y-3">
                {reviews.map((n) => (
                  <li key={n.id}>
                    <div className="flex items-baseline justify-between gap-2">
                      <span className="text-sm font-medium">{n.name}</span>
                      <span className={cn("font-mono text-xs", n.pass ? "text-pass" : "text-fail")}>
                        {n.score.toFixed(1)} {n.pass ? "in" : "hold"}
                      </span>
                    </div>
                    <p className="text-sm text-muted">{n.note}</p>
                    <p className="mt-1 text-xs text-faint">{n.polish}</p>
                  </li>
                ))}
              </ul>
            )}
          </Block>

          <Block title="Long 4K">
            {result?.filmPlan ? (
              <>
                <p className="font-mono text-sm text-accent">{result.filmPlan.runtimeLabel}</p>
                <p className="mt-2 text-sm text-muted">{result.filmPlan.handshake}</p>
                <p className="mt-2 text-xs text-faint">
                  Imagine only makes ~15s at a time. A long picture is {result.filmPlan.clipCount}{" "}
                  clips stitched. We do not press that button until the sim is one we like.
                </p>
                <Button
                  className="mt-3 w-full"
                  variant={weLike ? "outline" : "default"}
                  disabled={!reviewPass || weLike}
                  onClick={() => likeThis(production.id)}
                >
                  <Clapperboard className="h-4 w-4" />
                  {weLike
                    ? `Held — ${liked[production.id]?.minutes ?? commission?.minutes} min 4K · next clip ${commission?.nextClip ?? "—"}`
                    : "We like this — hold for 4K"}
                </Button>
                {weLike && (
                  <p className="mt-2 text-sm text-pass">
                    Handshake locked. Next continue we shoot clip 1 of{" "}
                    {liked[production.id]?.clipCount}. Nothing has been generated.
                  </p>
                )}
              </>
            ) : (
              <p className="text-sm text-muted">
                Run the Hale script. The 4K plan is written from the findings, then we decide
                together.
              </p>
            )}
          </Block>

          <Block title="Approve → X">
            {result && result.tweet ? (
              <>
                <pre className="whitespace-pre-wrap rounded-md bg-raised p-3 font-mono text-xs leading-relaxed">
                  {result.tweet}
                </pre>
                <SignedOut>
                  <p className="mt-3 text-sm text-muted">Sign in with X, then approve the draft.</p>
                </SignedOut>
                <SignedIn>
                  <Button
                    className="mt-3 w-full"
                    disabled={
                      done || result.gates.find((g) => g.id === "REVIEW")?.status !== "pass"
                    }
                    onClick={() => {
                      approve(production.id, result.tweet);
                      window.open(xComposeUrl(result.tweet), "_blank", "noopener,noreferrer");
                    }}
                  >
                    {done ? (
                      <>
                        <Check className="h-4 w-4" /> Approved
                      </>
                    ) : (
                      <>
                        <XIcon className="h-4 w-4" /> Approve & open draft
                      </>
                    )}
                  </Button>
                </SignedIn>
                <p className="mt-2 text-xs text-faint">
                  Nothing posts itself. Your click opens a draft on your account. Video attach
                  lands when Imagine is unlocked.
                </p>
              </>
            ) : (
              <p className="text-sm text-muted">Run a script to compose the caption from the findings.</p>
            )}
          </Block>
        </aside>
      </div>
    </div>
  );
}

function Block({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="border-b border-line px-4 py-4 last:border-b-0">
      <h3 className="mb-2 font-mono text-[11px] uppercase tracking-[0.18em] text-muted">{title}</h3>
      {children}
    </section>
  );
}
