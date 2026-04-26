import { IdeaStatus } from "@/lib/types";

interface StatusBadgeProps {
  status: IdeaStatus;
  size?: "sm" | "md";
}

const statusConfig: Record<
  IdeaStatus,
  { label: string; className: string; dot: string }
> = {
  Raw: {
    label: "Raw",
    className: "bg-status-raw-bg text-status-raw-text border-status-raw/40",
    dot: "bg-status-raw-text",
  },
  Developing: {
    label: "Developing",
    className:
      "bg-status-developing-bg text-status-developing-text border-status-developing/40",
    dot: "bg-status-developing-text",
  },
  Parked: {
    label: "Parked",
    className:
      "bg-status-parked-bg text-status-parked-text border-status-parked/40",
    dot: "bg-status-parked-text",
  },
};

export default function StatusBadge({ status, size = "sm" }: StatusBadgeProps) {
  const cfg = statusConfig[status];
  return (
    <span
      className={`inline-flex items-center gap-1.5 border rounded-full font-medium ${cfg.className} ${
        size === "sm" ? "text-xs px-2 py-0.5" : "text-sm px-3 py-1"
      }`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
      {cfg.label}
    </span>
  );
}
