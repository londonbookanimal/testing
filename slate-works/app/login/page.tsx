"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`,
      },
    });

    if (error) {
      setError(error.message);
    } else {
      setSent(true);
    }
    setLoading(false);
  }

  return (
    <div className="min-h-screen bg-paper flex items-center justify-center px-4">
      {/* Background texture */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 -left-32 w-96 h-96 bg-accent/5 rounded-full blur-3xl" />
        <div className="absolute bottom-1/4 -right-32 w-96 h-96 bg-ink/5 rounded-full blur-3xl" />
      </div>

      <div className="relative w-full max-w-sm">
        {/* Masthead */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-ink text-white text-xl mb-6 shadow-lg">
            🎞
          </div>
          <h1 className="text-2xl font-semibold text-ink tracking-tight">
            The Slate Works
          </h1>
          <p className="text-sm text-ink/50 mt-1.5">
            Documentary development, together
          </p>
        </div>

        <div className="card p-6">
          {!sent ? (
            <>
              <h2 className="text-base font-semibold text-ink mb-1">Sign in</h2>
              <p className="text-sm text-ink/55 mb-6">
                We'll send a magic link to your inbox — no password needed.
              </p>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label htmlFor="email" className="label">
                    Email address
                  </label>
                  <input
                    id="email"
                    type="email"
                    className="input"
                    placeholder="you@theslateworks.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    autoFocus
                  />
                </div>

                {error && (
                  <p className="text-sm text-accent bg-accent/10 rounded-lg px-3 py-2">
                    {error}
                  </p>
                )}

                <button
                  type="submit"
                  className="btn-primary w-full justify-center py-2.5"
                  disabled={loading || !email}
                >
                  {loading ? (
                    <>
                      <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Sending link…
                    </>
                  ) : (
                    "Send magic link"
                  )}
                </button>
              </form>
            </>
          ) : (
            <div className="text-center py-4">
              <div className="w-12 h-12 bg-status-developing-bg rounded-full flex items-center justify-center mx-auto mb-4">
                <svg
                  className="w-6 h-6 text-status-developing-text"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  />
                </svg>
              </div>
              <h2 className="text-base font-semibold text-ink mb-2">
                Check your inbox
              </h2>
              <p className="text-sm text-ink/55">
                We sent a magic link to{" "}
                <span className="font-medium text-ink">{email}</span>.
                <br />
                Click it to sign in.
              </p>
              <button
                className="btn-ghost mt-6 mx-auto text-xs"
                onClick={() => setSent(false)}
              >
                Use a different email
              </button>
            </div>
          )}
        </div>

        <p className="text-center text-xs text-ink/35 mt-6">
          The Slate Works · Internal team tool
        </p>
      </div>
    </div>
  );
}
