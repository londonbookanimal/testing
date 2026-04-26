"use client";

import { useState } from "react";
import { DigestEntry } from "@/lib/types";

interface MorningBriefEntryProps {
  entry: DigestEntry;
  onPromote?: () => void;
}

const PUBLICATION_COLOURS: Record<string, string> = {
  "The Guardian": "bg-[#052962] text-white",
  "The New York Times": "bg-ink text-white",
  "The Atlantic": "bg-[#bf0000] text-white",
  "The New Yorker": "bg-[#c00] text-white",
  "BBC News": "bg-[#bb1919] text-white",
};

export default function MorningBriefEntry({
  entry,
  onPromote,
}: MorningBriefEntryProps) {
  const [promoting, setPromoting] = useState(false);
  const [promoted, setPromoted] = useState(false);

  const pubColour =
    PUBLICATION_COLOURS[entry.publication] ?? "bg-ink/80 text-white";

  async function handlePromote() {
    setPromoting(true);
    try {
      const res = await fetch("/api/ideas", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          title: entry.title,
          note: `[From Morning Signal] ${entry.connection_note}\n\nOriginal story: ${entry.url}`,
          link: entry.url,
          tags: [entry.publication.toLowerCase().replace(/ /g, "-"), "morning-signal"],
          status: "Raw",
          created_by: "morning-signal",
        }),
      });
      if (res.ok) {
        setPromoted(true);
        onPromote?.();
      }
    } finally {
      setPromoting(false);
    }
  }

  return (
    <article className="card p-4 sm:p-5 hover:shadow-card-hover transition-shadow">
      <div className="flex items-start gap-3">
        {/* Publication badge */}
        <span
          className={`shrink-0 text-[10px] font-bold uppercase tracking-wide px-2 py-1 rounded-md mt-0.5 ${pubColour}`}
        >
          {entry.publication
            .replace("The ", "")
            .replace("New York Times", "NYT")}
        </span>

        <div className="flex-1 min-w-0">
          {/* Headline */}
          <a
            href={entry.url}
            target="_blank"
            rel="noopener noreferrer"
            className="block text-sm font-semibold text-ink hover:text-accent transition-colors leading-snug group"
          >
            {entry.title}
            <svg
              className="inline-block w-3 h-3 ml-1 mb-0.5 opacity-0 group-hover:opacity-60 transition-opacity"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
              />
            </svg>
          </a>

          {/* Connection note */}
          <p className="text-sm text-ink/65 mt-1.5 leading-relaxed">
            {entry.connection_note}
          </p>

          {/* Matched idea */}
          {entry.matched_idea_title && (
            <div className="mt-2 flex items-center gap-1.5">
              <span className="text-xs text-ink/40">Matched to →</span>
              <span className="text-xs font-medium text-ink/70 bg-paper-dark px-2 py-0.5 rounded-full">
                {entry.matched_idea_title}
              </span>
            </div>
          )}

          {/* Actions */}
          <div className="mt-3 flex items-center gap-2">
            {!promoted ? (
              <button
                onClick={handlePromote}
                disabled={promoting}
                className="btn-outline text-xs py-1 px-3"
              >
                {promoting ? (
                  <>
                    <span className="w-3 h-3 border border-ink/30 border-t-ink rounded-full animate-spin" />
                    Promoting…
                  </>
                ) : (
                  <>
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
                        d="M12 4v16m8-8H4"
                      />
                    </svg>
                    Add to Idea Wall
                  </>
                )}
              </button>
            ) : (
              <span className="text-xs text-status-developing-text bg-status-developing-bg px-3 py-1 rounded-full font-medium">
                ✓ Added to wall
              </span>
            )}

            <a
              href={entry.url}
              target="_blank"
              rel="noopener noreferrer"
              className="btn-ghost text-xs py-1 px-3"
            >
              Read story
            </a>
          </div>
        </div>
      </div>
    </article>
  );
}
