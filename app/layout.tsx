import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Mid Day Meal — Cash Book & Fund Register", description: "Cooking Cost Fund ਅਤੇ Fruit Fund ਦਾ automatic ਹਿਸਾਬ", icons: {icon:"/favicon.svg"} };
export default function RootLayout({children}: Readonly<{children:React.ReactNode}>) {return <html lang="en"><body>{children}</body></html>}
