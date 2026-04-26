"use client";

import { useState, useEffect, useRef } from "react";
import { IdeaStatus } from "@/lib/types";
import { createClient } from "@/lib/supabase/client";

interface AddIdeaModalProps {
  onClose: () => void;
  onAdded: () => void;
}

const STATUSES: IdeaStatus[] = ["Raw", "Developing", "Parked"];

export default function AddIdeaModal({ onClose, onAdded }: AddIdeaModalProps) {
  const [title, setTitle] = useState("");
  const [note, setNote] = useState("");
  const [link, setLink] = useState("");
  const [tagsRaw, setTagsRaw] = useState("");
  const [status, setStatus] = useState<IdeaStatus>("Raw");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const titleRef = useRef<HTMLInputElement>(null);
  const supabase = createClient();

  useEffect(() => {
    titleRef.current?.focus();

    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", handleKeyDown);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      document.body.style.overflow = "";
    };
  }, [onClose]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!title.trim()) return;

    setLoading(true);
    setError(null);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    const tags = tagsRaw
      .split(",")
      .map((t) => t.trim().toLowerCase())
      .filter(Boolean);

    const res = await fetch("/api/ideas", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        title: title.trim(),
        note: note.trim() || null,
        link: link.trim() || null,
        tags: tags.length ? tags : null,
        status,
        created_by: user?.email ?? "team",
      }),
    });

    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      setError(data.error ?? "Something went wrong");
      setLoading(false);
      return;
    }

    onAdded();
    onClose();
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-ink/30 backdrop-blur-sm animate-fade-in" />

      {/* Sheet / modal */}
      <div className="relative bg-white w-full sm:max-w-lg rounded-t-2xl sm:rounded-2xl shadow-modal animate-slide-up">
        {/* Drag handle (mobile) */}
        <div className="sm:hidden flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 bg-paper-dark rounded-full" />
        </div>

        <div className="px-5 pt-4 pb-2 sm:pt-6 sm:px-6">
          <div className="flex items-center justify-between mb-5">
            <h2 className="text-base font-semibold text-ink">New idea</h2>
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg hover:bg-paper-dark text-ink/50 hover:text-ink transition-all"
            >
              <svg
                className="w-4 h-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2.5}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="label">Title *</label>
              <input
                ref={titleRef}
                type="text"
                className="input"
                placeholder="What's the idea in one line?"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
              />
            </div>

            <div>
              <label className="label">Note / logline</label>
              <textarea
                className="textarea min-h-[80px]"
                placeholder="A sentence or two — what's the story? What's the angle?"
                value={note}
                onChange={(e) => setNote(e.target.value)}
                rows={3}
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Tags</label>
                <input
                  type="text"
                  className="input"
                  placeholder="climate, society…"
                  value={tagsRaw}
                  onChange={(e) => setTagsRaw(e.target.value)}
                />
                <p className="text-xs text-ink/40 mt-1">Comma-separated</p>
              </div>

              <div>
                <label className="label">Status</label>
                <select
                  className="input appearance-none cursor-pointer"
                  value={status}
                  onChange={(e) => setStatus(e.target.value as IdeaStatus)}
                >
                  {STATUSES.map((s) => (
                    <option key={s} value={s}>
                      {s}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div>
              <label className="label">Reference link</label>
              <input
                type="url"
                className="input"
                placeholder="https://…"
                value={link}
                onChange={(e) => setLink(e.target.value)}
              />
            </div>

            {error && (
              <p className="text-sm text-accent bg-accent/10 rounded-lg px-3 py-2">
                {error}
              </p>
            )}

            <div className="flex items-center gap-3 pt-2 pb-4 sm:pb-2">
              <button
                type="submit"
                className="btn-primary flex-1 justify-center py-2.5"
                disabled={loading || !title.trim()}
              >
                {loading ? (
                  <>
                    <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    Adding…
                  </>
                ) : (
                  "Add to wall"
                )}
              </button>
              <button
                type="button"
                onClick={onClose}
                className="btn-outline py-2.5 px-4"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}
