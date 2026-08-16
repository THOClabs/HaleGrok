import type { ErrorComponentProps } from "@tanstack/react-router";

export function AppErrorComponent({ error }: ErrorComponentProps) {
  return (
    <main className="grid min-h-dvh place-items-center bg-bg px-6 text-center text-fg">
      <div>
        <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted">fault</p>
        <h1 className="mt-2 text-2xl font-semibold">Something broke on the desk</h1>
        <p className="mt-3 max-w-md text-sm text-muted">
          {error.message || "Unexpected error. Reload the desk."}
        </p>
      </div>
    </main>
  );
}
