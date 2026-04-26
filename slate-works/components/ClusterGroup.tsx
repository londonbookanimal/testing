"use client";

import { useState } from "react";
import { Idea } from "@/lib/types";
import StatusBadge from "./StatusBadge";

interface ClusterGroupProps {
  name: string;
  ideas: Idea[];
  onRename: (newName: string) => void;
}

export default function ClusterGroup({
  name,
  ideas,
  onRename,
}: ClusterGroupProps) {
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(name);

  function commitRename() {
    const trimmed = draft.trim();
    if (trimmed && trimmed !== name) {
      onRename(trimmed);
    } else {
      setDraft(name);
    }
    setEditing(false);
  }

  return (
    <div className="flex flex-col gap-3">
      {/* Cluster header */}
      <div className="flex items-center gap-2 pb-2 border-b-2 border-ink/10">
        <div className="w-2 h-2 rounded-full bg-accent shrink-0" />
        {editing ? (
          <form
            onSubmit={(e) => {
              e.preventDefault();
              commitRename();
            }}
            className="flex-1 flex gap-2"
          >
            <input
              autoFocus
              type="text"
              className="input py-0.5 text-sm font-semibold flex-1"
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              onBlur={commitRename}
            />
          </form>
        ) : (
          <button
            onClick={() => setEditing(true)}
            className="flex-1 text-left text-sm font-semibold text-ink hover:text-accent transition-colors group flex items-center gap-1.5"
            title="Click to rename cluster"
          >
            {name}
            <svg
              className="w-3 h-3 text-ink/30 group-hover:text-accent opacity-0 group-hover:opacity-100 transition-all"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
              />
            </svg>
          </button>
        )}
        <span className="text-xs text-ink/40 shrink-0">
          {ideas.length} {ideas.length === 1 ? "idea" : "ideas"}
        </span>
      </div>

      {/* Ideas in cluster */}
      <div className="space-y-2">
        {ideas.map((idea) => (
          <div
            key={idea.id}
            className="card p-3 hover:shadow-card-hover transition-shadow"
          >
            <div className="flex items-start justify-between gap-2">
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-ink leading-snug">
                  {idea.title}
                </p>
                {idea.note && (
                  <p className="text-xs text-ink/55 mt-1 leading-relaxed line-clamp-2">
                    {idea.note}
                  </p>
                )}
                {idea.tags && idea.tags.length > 0 && (
                  <div className="flex flex-wrap gap-1 mt-1.5">
                    {idea.tags.slice(0, 3).map((tag) => (
                      <span key={tag} className="tag-pill text-[10px]">
                        {tag}
                      </span>
                    ))}
                  </div>
                )}
              </div>
              <div className="shrink-0 flex flex-col items-end gap-1.5">
                <StatusBadge status={idea.status} />
                <span className="text-xs text-ink/40 flex items-center gap-1">
                  <svg
                    className="w-3 h-3"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                    strokeWidth={2.5}
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      d="M4.5 15.75l7.5-7.5 7.5 7.5"
                    />
                  </svg>
                  {idea.votes}
                </span>
              </div>
            </div>
          </div>
        ))}

        {ideas.length === 0 && (
          <p className="text-xs text-ink/35 italic px-1">
            No matching ideas found
          </p>
        )}
      </div>
    </div>
  );
}
