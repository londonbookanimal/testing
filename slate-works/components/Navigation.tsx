"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useRouter } from "next/navigation";

const navLinks = [
  { href: "/", label: "Idea Wall", icon: "◈" },
  { href: "/cluster", label: "Clusters", icon: "⬡" },
  { href: "/morning-signal", label: "Morning Signal", icon: "◎" },
];

export default function Navigation() {
  const pathname = usePathname();
  const router = useRouter();
  const [signingOut, setSigningOut] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);

  // Don't render nav on login page
  if (pathname === "/login") return null;

  async function handleSignOut() {
    setSigningOut(true);
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
  }

  return (
    <nav className="sticky top-0 z-40 bg-paper/90 backdrop-blur-md border-b border-paper-dark/80">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">
          {/* Wordmark */}
          <Link
            href="/"
            className="flex items-center gap-2.5 font-semibold text-ink hover:text-ink/80 transition-colors group"
          >
            <span className="text-lg leading-none group-hover:scale-110 transition-transform">
              🎞
            </span>
            <span className="text-sm tracking-tight hidden sm:block">
              The Slate Works
            </span>
            <span className="text-sm tracking-tight sm:hidden">TSW</span>
          </Link>

          {/* Desktop nav */}
          <div className="hidden sm:flex items-center gap-1">
            {navLinks.map((link) => {
              const active = pathname === link.href;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-all duration-150 ${
                    active
                      ? "bg-ink text-white shadow-sm"
                      : "text-ink/60 hover:text-ink hover:bg-paper-dark"
                  }`}
                >
                  <span className="text-xs opacity-70">{link.icon}</span>
                  {link.label}
                </Link>
              );
            })}
          </div>

          {/* Sign out */}
          <div className="flex items-center gap-2">
            <button
              onClick={handleSignOut}
              disabled={signingOut}
              className="hidden sm:flex btn-ghost text-xs py-1.5 px-3"
            >
              {signingOut ? "Signing out…" : "Sign out"}
            </button>

            {/* Mobile hamburger */}
            <button
              className="sm:hidden p-2 rounded-lg hover:bg-paper-dark transition-colors"
              onClick={() => setMenuOpen(!menuOpen)}
              aria-label="Toggle menu"
            >
              <div className="space-y-1.5">
                <span
                  className={`block w-5 h-0.5 bg-ink transition-all ${menuOpen ? "rotate-45 translate-y-2" : ""}`}
                />
                <span
                  className={`block w-5 h-0.5 bg-ink transition-all ${menuOpen ? "opacity-0" : ""}`}
                />
                <span
                  className={`block w-5 h-0.5 bg-ink transition-all ${menuOpen ? "-rotate-45 -translate-y-2" : ""}`}
                />
              </div>
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {menuOpen && (
          <div className="sm:hidden pb-3 border-t border-paper-dark/60 pt-2 animate-fade-in">
            {navLinks.map((link) => {
              const active = pathname === link.href;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  onClick={() => setMenuOpen(false)}
                  className={`flex items-center gap-2 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                    active
                      ? "bg-ink text-white"
                      : "text-ink/70 hover:bg-paper-dark hover:text-ink"
                  }`}
                >
                  <span className="text-xs">{link.icon}</span>
                  {link.label}
                </Link>
              );
            })}
            <button
              onClick={handleSignOut}
              className="w-full text-left px-3 py-2.5 text-sm text-ink/50 hover:text-ink transition-colors mt-1"
            >
              Sign out
            </button>
          </div>
        )}
      </div>
    </nav>
  );
}
