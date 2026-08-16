import { createFileRoute } from "@tanstack/react-router";
import { Splash } from "@/components/splash/Splash";

export const Route = createFileRoute("/films")({
  component: Splash,
  ssr: false,
});
