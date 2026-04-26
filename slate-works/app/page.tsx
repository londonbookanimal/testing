"use client";

import { useEffect, useState, useCallback } from "react";
import { createClient } from "@/lib/supabase/client";
import { Idea, IdeaStatus, SortOption } from "@/lib/types";
import IdeaCard from "@/components/IdeaCard";
import AddIdeaModal from "@/components/AddIdeaModal";
import SortBar from "@/components/SortBar";

function sortIdeas(ideas: Idea[], sort: SortOption): Idea[] {
  const copy = [...ideas];
  if (sort === "votes") {
    return copy.sort((a, b) => b.votes - a.votes);
  }
  if (sort === "status") {
    const order: Record<IdeaStatus, number> = {
      Developing: 0,
      Raw: 1,
      Parked: 2,
    };
    return copy.sort((a, b) => order[a.status] - order[b.status]);
  }
  // date
  return copy.sort(
    (a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  );
}

export default function IdeaWall() {
  const [ideas, setIdeas] = useState<Idea[]>([]);
  const [loading, setLoading] = useState(true);
  const [sort, setSort] = useState<SortOption>("date");
  const [showModal, setShowModal] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const supabase = createClient();

  const fetchIdeas = useCallback(async () => {
    const res = await fetch("/api/ideas");
    if (res.ok) {
      const data = await res.json();
      setIdeas(data.ideas ?? []);
    } else {
      setError("Failed to load ideas");
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchIdeas();

    // Supabase Realtime subscription
    const channel = supabase
      .channel("ideas-realtime")
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "ideas" },
        (payload) => {
          const newIdea = payload.new as Idea;
          setIdeas((prev) => {
            if (prev.find((i) => i.id === newIdea.id)) return prev;
            return [newIdea, ...prev];
          });
        }
      )
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "ideas" },
        (payload) => {
          const updated = payload.new as Idea;
          setIdeas((prev) =>
            prev.map((i) => (i.id === updated.id ? { ...i, ...updated } : i))
          );
        }
      )
      .on(
        "postgres_changes",
        { event: "DELETE", schema: "public", table: "ideas" },
        (payload) => {
          const deleted = payload.old as { id: string };
          setIdeas((prev) => prev.filter((i) => i.id !== deleted.id));
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, fetchIdeas]);

  function handleStatusChange(id: string, status: IdeaStatus) {
    setIdeas((prev) =>
      prev.map((i) => (i.id === id ? { ...i, status } : i))
    );
  }

  function handleDelete(id: string) {
    setIdeas((prev) => prev.filter((i) => i.id !== id));
  }

  const sorted = sortIdeas(ideas, sort);

  return (
    <>
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Page header */}
        <div className="mb-8">
          <div className="flex items-end justify-between">
            <div>
              <h1 className="text-2xl sm:text-3xl font-semibold text-ink tracking-tight">
                Idea Wall
              </h1>
              <p className="text-sm text-ink/50 mt-1">
                Real-time · shared across the team
              </p>
            </div>
            {/* Live indicator */}
            <div className="hidden sm:flex items-center gap-1.5 text-xs text-ink/40">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-status-developing opacity-75" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-status-developing" />
              </span>
              Live
            </div>
          </div>
        </div>

        {/* Sort bar */}
        {!loading && (
          <div className="mb-6">
            <SortBar current={sort} onChange={setSort} total={ideas.length} />
          </div>
        )}

        {/* Content */}
        {loading ? (
          <div className="masonry-grid">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="masonry-item">
                <div
                  className="card p-4 animate-pulse"
                  style={{ height: `${140 + (i % 3) * 40}px` }}
                >
                  <div className="h-4 bg-paper-dark rounded w-3/4 mb-3" />
                  <div className="h-3 bg-paper-dark rounded w-full mb-2" />
                  <div className="h-3 bg-paper-dark rounded w-5/6" />
                </div>
              </div>
            ))}
          </div>
        ) : error ? (
          <div className="text-center py-20">
            <p className="text-ink/50 mb-4">{error}</p>
            <button onClick={fetchIdeas} className="btn-outline">
              Try again
            </button>
          </div>
        ) : ideas.length === 0 ? (
          <div className="text-center py-20">
            <div className="w-16 h-16 bg-paper-dark rounded-2xl flex items-center justify-center mx-auto mb-5 text-2xl">
              🎬
            </div>
            <h2 className="text-base font-semibold text-ink mb-2">
              The wall is blank
            </h2>
            <p className="text-sm text-ink/50 mb-6 max-w-xs mx-auto">
              Add your first idea and start building the slate.
            </p>
            <button
              onClick={() => setShowModal(true)}
              className="btn-primary mx-auto"
            >
              Add first idea
            </button>
          </div>
        ) : (
          <div className="masonry-grid">
            {sorted.map((idea) => (
              <IdeaCard
                key={idea.id}
                idea={idea}
                onStatusChange={handleStatusChange}
                onDelete={handleDelete}
              />
            ))}
          </div>
        )}
      </div>

      {/* Floating add button */}
      {!loading && (
        <button
          onClick={() => setShowModal(true)}
          className="fixed bottom-6 right-6 z-30 w-14 h-14 bg-ink text-white rounded-full shadow-modal hover:bg-ink-light active:scale-95 transition-all duration-150 flex items-center justify-center group"
          aria-label="Add new idea"
        >
          <svg
            className="w-6 h-6 group-hover:rotate-90 transition-transform duration-200"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            strokeWidth={2.5}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 4v16m8-8H4"
            />
          </svg>
        </button>
      )}

      {/* Add modal */}
      {showModal && (
        <AddIdeaModal
          onClose={() => setShowModal(false)}
          onAdded={fetchIdeas}
        />
      )}
    </>
  );
}
