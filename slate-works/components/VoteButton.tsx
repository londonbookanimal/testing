"use client";

import { useState } from "react";

interface VoteButtonProps {
  votes: number;
  ideaId: string;
  onVote?: (newVotes: number) => void;
}

export default function VoteButton({ votes, ideaId, onVote }: VoteButtonProps) {
  const [loading, setLoading] = useState(false);
  const [localVotes, setLocalVotes] = useState(votes);
  const [voted, setVoted] = useState(false);

  async function handleVote(e: React.MouseEvent) {
    e.stopPropagation();
    if (loading || voted) return;

    setLoading(true);
    // Optimistic update
    const newVotes = localVotes + 1;
    setLocalVotes(newVotes);
    setVoted(true);

    try {
      const res = await fetch(`/api/ideas/${ideaId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "vote" }),
      });

      if (!res.ok) {
        // Revert
        setLocalVotes(localVotes);
        setVoted(false);
      } else {
        const data = await res.json();
        setLocalVotes(data.votes ?? newVotes);
        onVote?.(data.votes ?? newVotes);
      }
    } catch {
      setLocalVotes(localVotes);
      setVoted(false);
    } finally {
      setLoading(false);
    }
  }

  return (
    <button
      onClick={handleVote}
      disabled={loading || voted}
      title={voted ? "Voted!" : "Upvote this idea"}
      className={`group flex items-center gap-1.5 px-2 py-1 rounded-lg text-xs font-semibold transition-all duration-150 ${
        voted
          ? "bg-accent/10 text-accent cursor-default"
          : "hover:bg-paper-dark text-ink/50 hover:text-ink"
      }`}
    >
      <svg
        className={`w-3.5 h-3.5 transition-transform ${
          !voted ? "group-hover:-translate-y-0.5" : ""
        }`}
        fill={voted ? "currentColor" : "none"}
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
      <span>{localVotes}</span>
    </button>
  );
}
