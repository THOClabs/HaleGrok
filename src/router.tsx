import { createRouter, useRouter } from "@tanstack/react-router";
import { routeTree } from "./routeTree.gen";
import { AppErrorComponent } from "@/lib/error-component";

function NotFound() {
  const router = useRouter();
  return (
    <div className="mx-auto max-w-lg px-6 py-24 text-fg">
      <p className="font-mono text-xs uppercase tracking-[0.18em] text-muted">404</p>
      <h1 className="mt-2 text-3xl font-semibold">No such production</h1>
      <button
        type="button"
        className="mt-6 text-accent underline-offset-4 hover:underline"
        onClick={() => router.navigate({ to: "/" })}
      >
        Back to the desk
      </button>
    </div>
  );
}

export const getRouter = () => {
  const router = createRouter({
    routeTree,
    scrollRestoration: true,
    defaultPreload: "intent",
    defaultErrorComponent: AppErrorComponent,
    defaultNotFoundComponent: NotFound,
    defaultPendingComponent: () => (
      <div className="grid min-h-dvh place-items-center bg-bg text-muted">Opening the desk…</div>
    ),
    defaultOnCatch: (error: Error) => {
      console.error(error);
    },
  });
  return router;
};
