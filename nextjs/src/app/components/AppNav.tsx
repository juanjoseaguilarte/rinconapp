"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const LINKS = [
  { href: "/power4", label: "Power 4" },
  { href: "/delta-neutral", label: "Delta Neutral" },
];

export default function AppNav() {
  const pathname = usePathname();

  return (
    <nav className="border-b border-slate-800 bg-slate-950">
      <div className="max-w-5xl mx-auto px-4 flex gap-1 pt-2">
        {LINKS.map(({ href, label }) => {
          const active = pathname.startsWith(href);
          return (
            <Link
              key={href}
              href={href}
              className={`px-4 py-2 text-sm font-semibold rounded-t-lg border-b-2 transition-colors ${
                active
                  ? "border-slate-200 text-white bg-slate-900"
                  : "border-transparent text-slate-500 hover:text-slate-300"
              }`}
            >
              {label}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
