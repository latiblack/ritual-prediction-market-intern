import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Ritual Prediction Market Intern — AI Market Analysis",
  description: "Browse Polymarket markets and get AI analysis. No backend required.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
