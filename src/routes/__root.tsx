import { HeadContent, Outlet, Scripts, createRootRoute } from "@tanstack/react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { AuthProvider } from "@/lib/auth/provider";
import { PreviewHostBridge } from "@/components/preview-host-bridge";
import appCss from "@/styles.css?url";
import favicon from "@/../public/favicon.svg?url";

const queryClient = new QueryClient();

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: "utf-8" },
      { name: "viewport", content: "width=device-width, initial-scale=1" },
      { title: "HaleGrok House" },
      {
        name: "description",
        content: "Two-minute films written by Hale orbital mechanics. Watch, then post to X.",
      },
      { property: "og:title", content: "HaleGrok" },
      {
        property: "og:description",
        content: "Code-sim driven cinema. 100 films. Approve to post.",
      },
      { property: "og:image", content: "/og.jpg" },
      { name: "twitter:card", content: "summary_large_image" },
      { name: "twitter:site", content: "@thenlaguna" },
    ],
    links: [
      { rel: "stylesheet", href: appCss },
      { rel: "icon", href: favicon },
    ],
  }),
  component: RootDocument,
});

function RootDocument() {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <PreviewHostBridge />
            <Outlet />
          </AuthProvider>
        </QueryClientProvider>
        <Scripts />
      </body>
    </html>
  );
}
