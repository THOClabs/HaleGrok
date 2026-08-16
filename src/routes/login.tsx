import { createFileRoute } from "@tanstack/react-router";
import { GROK_PROVIDERS, signIn } from "@/lib/auth/client";
import { SignedIn, SignedOut } from "@/lib/auth/gates";
import { Navigate } from "@tanstack/react-router";
import { Button } from "@/components/ui/button";

export const Route = createFileRoute("/login")({
  component: LoginPage,
});

function LoginPage() {
  return (
    <div className="grid min-h-dvh place-items-center bg-bg px-6 text-fg">
      <SignedIn>
        <Navigate to="/" />
      </SignedIn>
      <SignedOut>
        <div className="w-full max-w-sm">
          <p className="font-mono text-[11px] uppercase tracking-[0.18em] text-muted">HaleGrok</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-tight">Sign in to approve</h1>
          <p className="mt-3 text-sm text-muted">
            Posts only leave this desk when you click Approve. Sign in with X to draft on
            @thenlaguna.
          </p>
          <div className="mt-8 flex flex-col gap-2">
            {GROK_PROVIDERS.map((p) => (
              <Button
                key={p.providerId}
                variant={p.idp === "twitter" ? "default" : "outline"}
                onClick={() => void signIn(p.providerId)}
              >
                Continue with {p.label}
              </Button>
            ))}
          </div>
        </div>
      </SignedOut>
    </div>
  );
}
