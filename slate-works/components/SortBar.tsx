"use client";

import { SortOption } from "@/lib/types";

interface SortBarProps {
  current: SortOption;
  onChange: (sort: SortOption) => void;
  total: number;
}

const OPTIONS: { value: SortOption; label: string }[] = [
  { value: "date", label: "Newest" },
  { value: "votes", label: "Most voted" },
  { value: "status", label: "Status" },
];

export default function SortBar({ current, onChange, total }: SortBarProps) {
  return (
    <div className="flex items-center justify-between">
      <p className="text-sm text-ink/50">
        <span className="font-semibold text-ink">{total}</span>{" "}
        {total === 1 ? "idea" : "ideas"} on the wall
      </p>

      <div className="flex items-center gap-0.5 bg-paper-dark/60 rounded-lg p-0.5">
        {OPTIONS.map((opt) => (
          <button
            key={opt.value}
            onClick={() => onChange(opt.value)}
            className={`px-3 py-1.5 rounded-md text-xs font-medium transition-all duration-150 ${
              current === opt.value
                ? "bg-white text-ink shadow-sm"
                : "text-ink/50 hover:text-ink"
            }`}
          >
            {opt.label}
          </button>
        ))}
      </div>
    </div>
  );
}
