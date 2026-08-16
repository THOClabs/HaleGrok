import { X_HANDLE } from "./types";

export function xComposeUrl(text: string): string {
  const trimmed = text.slice(0, 280);
  return `https://x.com/intent/post?text=${encodeURIComponent(trimmed)}`;
}

export function xProfileUrl(): string {
  return `https://x.com/${X_HANDLE}`;
}
