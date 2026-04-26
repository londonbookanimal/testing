"use client";

import { useState } from "react";
import { Idea, IdeaStatus, Comment } from "@/lib/types";
import StatusBadge from "./StatusBadge";
import VoteButton from "./VoteButton";
import { createClient } from "@/lib/supabase/client";

interface IdeaCardProps {
  idea: Idea;
  onStatusChange?: (id: string, status: IdeaStatus) => void;
  onDelete?: (id: string) => void;
}

const STATUSES: IdeaStatus[] = ["Raw", "Developing", "Parked"];

export default function IdeaCard({
  idea,
  onStatusChange,
  onDelete,
}: IdeaCardProps) {
  const [expanded, setExpanded] = useState(false);
  const [comments, setComments] = useState<Comment[]>([]);
  const [loadingComments, setLoadingComments] = useState(false);
  const [newComment, setNewComment] = useState("");
  const [postingComment, setPostingComment] = useState(false);
  const [menuOpen, setMenuOpen] = useState(false);
  const [currentVotes, setCurrentVotes] = useState(idea.votes);

  const supabase = createClient();

  async function loadComments() {
    if (loadingComments) return;
    setLoadingComments(true);
    try {
      const res = await fetch(`/api/ideas/${idea.id}/comments`);
      if (res.ok) {
        const data = await res.json();
        setComments(data.comments ?? []);
      }
    } finally {
      setLoadingComments(false);
    }
  }

  async function toggleExpanded() {
    const next = !expanded;
    setExpanded(next);
    if (next && comments.length === 0) {
      await loadComments();
    }
  }

  async function handleCommentSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!newComment.trim() || postingComment) return;

    setPostingComment(true);
    const {
      data: { user },
    } = await supabase.auth.getUser();

    try {
      const res = await fetch(`/api/ideas/${idea.id}/comments`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          body: newComment.trim(),
          author: user?.email ?? "Anonymous",
        }),
      });
      if (res.ok) {
        const data = await res.json();
        setComments((prev) => [...prev, data.comment]);
        setNewComment("");
      }
    } finally {
      setPostingComment(false);
    }
  }

  async function handleStatusChange(status: IdeaStatus) {
    setMenuOpen(false);
    await fetch(`/api/ideas/${idea.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ action: "status", status }),
    });
    onStatusChange?.(idea.id, status);
  }

  async function handleDelete() {
    setMenuOpen(false);
    if (!confirm("Remove this idea from the wall?")) return;
    await fetch(`/api/ideas/${idea.id}`, { method: "DELETE" });
    onDelete?.(idea.id);
  }

  const commentCount = idea.comment_count ?? comments.length;

  return (
    <div className="masonry-item">
      <article className="card p-4 group relative">
        {/* Status strip on left edge */}
        <div
          className={`absolute left-0 top-4 bottom-4 w-0.5 rounded-full ${
            idea.status === "Developing"
              ? "bg-status-developing"
              : idea.status === "Parked"
                ? "bg-status-parked"
                : "bg-status-raw"
          }`}
        />

        {/* Header row */}
        <div className="flex items-start justify-between gap-2 pl-3">
          <div className="flex-1 min-w-0">
            <h3 className="text-sm font-semibold text-ink leading-snug text-balance pr-2">
              {idea.title}
            </h3>
            {idea.link && (
              <a
                href={idea.link}
                target="_blank"
                rel="noopener noreferrer"
                onClick={(e) => e.stopPropagation()}
                className="inline-flex items-center gap-1 text-xs text-accent hover:underline mt-0.5 truncate max-w-full"
              >
                <svg
                  className="w-3 h-3 shrink-0"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth={2}
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101"
                  />
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M10.172 13.828a4 4 0 015.656 0l4-4a4 4 0 10-5.656-5.656l-1.1 1.1"
                  />
                </svg>
                <span className="truncate">{new URL(idea.link).hostname}</span>
              </a>
            )}
          </div>

          {/* Context menu */}
          <div className="relative shrink-0">
            <button
              onClick={(e) => {
                e.stopPropagation();
                setMenuOpen(!menuOpen);
              }}
              className="p-1 rounded-md text-ink/30 hover:text-ink/70 hover:bg-paper-dark opacity-0 group-hover:opacity-100 transition-all"
              aria-label="Card options"
            >
              <svg
                className="w-4 h-4"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <circle cx="5" cy="12" r="1.5" />
                <circle cx="12" cy="12" r="1.5" />
                <circle cx="19" cy="12" r="1.5" />
              </svg>
            </button>

            {menuOpen && (
              <>
                <div
                  className="fixed inset-0 z-10"
                  onClick={() => setMenuOpen(false)}
                />
                <div className="absolute right-0 top-8 z-20 bg-white rounded-xl shadow-modal border border-paper-dark/60 py-1.5 w-44 animate-fade-in">
                  <p className="px-3 py-1 text-xs font-semibold text-ink/40 uppercase tracking-wide">
                    Status
                  </p>
                  {STATUSES.map((s) => (
                    <button
                      key={s}
                      onClick={() => handleStatusChange(s)}
                      className={`w-full text-left px-3 py-1.5 text-sm hover:bg-paper transition-colors ${
                        idea.status === s
                          ? "text-ink font-medium"
                          : "text-ink/70"
                      }`}
                    >
                      {s === idea.status ? `✓ ${s}` : s}
                    </button>
                  ))}
                  <div className="border-t border-paper-dark/60 mt-1.5 pt-1.5">
                    <button
                      onClick={handleDelete}
                      className="w-full text-left px-3 py-1.5 text-sm text-accent hover:bg-accent/5 transition-colors"
                    >
                      Remove
                    </button>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>

        {/* Note */}
        {idea.note && (
          <p className="text-sm text-ink/65 mt-2 pl-3 leading-relaxed line-clamp-4">
            {idea.note}
          </p>
        )}

        {/* Tags */}
        {idea.tags && idea.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mt-3 pl-3">
            {idea.tags.map((tag) => (
              <span key={tag} className="tag-pill">
                {tag}
              </span>
            ))}
          </div>
        )}

        {/* Footer row */}
        <div className="flex items-center justify-between mt-3 pl-3 pt-3 border-t border-paper-dark/50">
          <div className="flex items-center gap-1">
            <VoteButton
              votes={currentVotes}
              ideaId={idea.id}
              onVote={(v) => setCurrentVotes(v)}
            />
            <button
              onClick={toggleExpanded}
              className="flex items-center gap-1.5 px-2 py-1 rounded-lg text-xs text-ink/50 hover:text-ink hover:bg-paper-dark transition-all"
            >
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
                  d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
                />
              </svg>
              <span>{commentCount > 0 ? commentCount : "Add note"}</span>
            </button>
          </div>

          <StatusBadge status={idea.status} />
        </div>

        {/* Expanded comments */}
        {expanded && (
          <div className="mt-3 pl-3 animate-fade-in">
            <div className="border-t border-paper-dark/50 pt-3 space-y-3">
              {loadingComments ? (
                <p className="text-xs text-ink/40 animate-pulse">
                  Loading…
                </p>
              ) : comments.length > 0 ? (
                comments.map((c) => (
                  <div key={c.id} className="group/comment">
                    <div className="flex items-baseline gap-2">
                      <span className="text-xs font-semibold text-ink/70">
                        {c.author ?? "Anonymous"}
                      </span>
                      <span className="text-xs text-ink/30">
                        {new Date(c.created_at).toLocaleDateString("en-GB", {
                          day: "numeric",
                          month: "short",
                        })}
                      </span>
                    </div>
                    <p className="text-sm text-ink/75 mt-0.5 leading-relaxed">
                      {c.body}
                    </p>
                  </div>
                ))
              ) : (
                <p className="text-xs text-ink/35 italic">No notes yet</p>
              )}

              <form onSubmit={handleCommentSubmit} className="flex gap-2 pt-1">
                <input
                  type="text"
                  className="input py-1.5 text-xs flex-1"
                  placeholder="Add a note…"
                  value={newComment}
                  onChange={(e) => setNewComment(e.target.value)}
                />
                <button
                  type="submit"
                  disabled={!newComment.trim() || postingComment}
                  className="btn-primary py-1.5 px-3 text-xs shrink-0"
                >
                  {postingComment ? "…" : "Post"}
                </button>
              </form>
            </div>
          </div>
        )}
      </article>
    </div>
  );
}
