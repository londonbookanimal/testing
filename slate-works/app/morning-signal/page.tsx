"use client";

import { useEffect, useState } from "react";
import { MorningBrief, DigestEntry } from "@/lib/types";
import MorningBriefEntry from "@/components/MorningBriefEntry";
import { createClient } from "@/lib/supabase/client";

export default function MorningSignalPage() {
  const [briefs, setBriefs] = useState<MorningBrief[]>([]);
  const [activeBrief, setActiveBrief] = useState<MorningBrief | null>(null);
  const [generating, setGenerating] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [promoted, setPromoted] = useState(0);

  const supabase = createClient();

  async function loadBriefs() {
    const { data, error } = await supabase
      .from("morning_briefs")
      .select("*")
      .order("generated_at", { ascending: false })
      .limit(10);

    if (!error && data) {
      setBriefs(data as MorningBrief[]);
      if (data.length > 0) {
        setActiveBrief(data[0] as MorningBrief);
      }
    }
    setLoading(false);
  }

  useEffect(() => {
    loadBriefs();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function handleGenerate() {
    setGenerating(true);
    setError(null);

    try {
      const {
        data: { user },
      } = await supabase.auth.getUser();

      const res = await fetch("/api/morning-brief", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ triggered_by: user?.email ?? "manual" }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? "Brief generation failed");
      }

      const data = await res.json();
      const newBrief: MorningBrief = data.brief;
      setBriefs((prev) => [newBrief, ...prev]);
      setActiveBrief(newBrief);
      setPromoted(0);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong");
    } finally {
      setGenerating(false);
    }
  }

  const entries: DigestEntry[] = activeBrief?.digest_json ?? [];

  return (
    <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end gap-4 justify-between mb-8">
        <div>
          <h1 className="text-2xl sm:text-3xl font-semibold text-ink tracking-tight">
            Morning Signal
          </h1>
          <p className="text-sm text-ink/50 mt-1">
            Daily stories from the world that match your ideas
          </p>
          <div className="flex items-center gap-2 mt-2">
            <span className="text-xs text-ink/35 bg-paper-dark px-2 py-0.5 rounded-full">
              The Guardian
            </span>
            <span className="text-xs text-ink/35 bg-paper-dark px-2 py-0.5 rounded-full">
              NYT
            </span>
            <span className="text-xs text-ink/35 bg-paper-dark px-2 py-0.5 rounded-full">
              The Atlantic
            </span>
            <span className="text-xs text-ink/35 bg-paper-dark px-2 py-0.5 rounded-full">
              The New Yorker
            </span>
            <span className="text-xs text-ink/35 bg-paper-dark px-2 py-0.5 rounded-full">
              BBC News
            </span>
          </div>
        </div>

        <button
          onClick={handleGenerate}
          disabled={generating}
          className="btn-accent self-start sm:self-auto py-2.5 px-5 shrink-0"
        >
          {generating ? (
            <>
              <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              Scanning the news…
            </>
          ) : (
            <>
              <svg
                className="w-4 h-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M12 3v2.25m6.364.386l-1.591 1.591M21 12h-2.25m-.386 6.364l-1.591-1.591M12 18.75V21m-4.773-4.227l-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0z"
                />
              </svg>
              Generate brief
            </>
          )}
        </button>
      </div>

      {error && (
        <div className="bg-accent/10 border border-accent/20 rounded-xl px-4 py-3 mb-6 text-sm text-accent">
          {error}
        </div>
      )}

      {/* Brief history tabs */}
      {!loading && briefs.length > 1 && (
        <div className="flex gap-2 mb-6 overflow-x-auto pb-1">
          {briefs.map((brief) => (
            <button
              key={brief.id}
              onClick={() => {
                setActiveBrief(brief);
                setPromoted(0);
              }}
              className={`shrink-0 text-xs px-3 py-1.5 rounded-lg font-medium transition-all ${
                activeBrief?.id === brief.id
                  ? "bg-ink text-white"
                  : "bg-paper-dark text-ink/60 hover:text-ink"
              }`}
            >
              {new Date(brief.generated_at).toLocaleDateString("en-GB", {
                weekday: "short",
                day: "numeric",
                month: "short",
              })}
              {brief.triggered_by === "cron" && (
                <span className="ml-1 opacity-60">⏰</span>
              )}
            </button>
          ))}
        </div>
      )}

      {/* Content */}
      {loading ? (
        <div className="space-y-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="card p-5 animate-pulse">
              <div className="flex gap-3">
                <div className="w-16 h-6 bg-paper-dark rounded" />
                <div className="flex-1 space-y-2">
                  <div className="h-4 bg-paper-dark rounded w-3/4" />
                  <div className="h-3 bg-paper-dark rounded w-full" />
                  <div className="h-3 bg-paper-dark rounded w-5/6" />
                </div>
              </div>
            </div>
          ))}
        </div>
      ) : !activeBrief ? (
        <div className="text-center py-20">
          <div className="w-16 h-16 bg-paper-dark rounded-2xl flex items-center justify-center mx-auto mb-5 text-2xl">
            ◎
          </div>
          <h2 className="text-base font-semibold text-ink mb-2">
            No briefs yet
          </h2>
          <p className="text-sm text-ink/50 mb-6 max-w-sm mx-auto">
            Hit "Generate brief" to have Claude scan today's news from five
            major publications and find stories that connect to your ideas.
          </p>
          <p className="text-xs text-ink/35">
            Runs automatically at 8am on weekdays via Vercel cron
          </p>
        </div>
      ) : entries.length === 0 ? (
        <div className="text-center py-12">
          <p className="text-sm text-ink/50">
            No matching stories found in this brief.
          </p>
          <button
            onClick={handleGenerate}
            className="btn-outline mt-4 mx-auto"
          >
            Regenerate
          </button>
        </div>
      ) : (
        <>
          {/* Brief meta */}
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-sm font-medium text-ink">
                {entries.length} {entries.length === 1 ? "story" : "stories"}{" "}
                matched
              </p>
              <p className="text-xs text-ink/40 mt-0.5">
                Generated{" "}
                {new Date(activeBrief.generated_at).toLocaleString("en-GB", {
                  dateStyle: "full",
                  timeStyle: "short",
                })}
                {activeBrief.triggered_by &&
                  ` · by ${activeBrief.triggered_by}`}
              </p>
            </div>
            {promoted > 0 && (
              <span className="text-xs text-status-developing-text bg-status-developing-bg px-3 py-1 rounded-full font-medium">
                {promoted} added to wall
              </span>
            )}
          </div>

          <div className="space-y-4">
            {entries.map((entry, idx) => (
              <MorningBriefEntry
                key={`${activeBrief.id}-${idx}`}
                entry={entry}
                onPromote={() => setPromoted((p) => p + 1)}
              />
            ))}
          </div>
        </>
      )}

      {/* Cron info */}
      <div className="mt-10 pt-6 border-t border-paper-dark/60">
        <div className="flex items-center gap-2 text-xs text-ink/35">
          <svg
            className="w-3.5 h-3.5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          Scheduled daily at 8am Monday–Friday via Vercel cron
        </div>
      </div>
    </div>
  );
}
