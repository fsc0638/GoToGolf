import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "GoToGolf Web Fullstack",
  description: "Fullstack 測試台：Windows 上驗證高爾夫計分流程",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="zh-Hant">
      <body>{children}</body>
    </html>
  );
}
