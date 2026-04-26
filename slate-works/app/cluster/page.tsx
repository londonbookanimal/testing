"use client";

import { useEffect, useState } from "react";
import { Idea, Cluster, ClusterMap } from "@/lib/types";
import ClusterGroup from "@/components/ClusterGroup";

export default function ClusterPage() {
  const [ideas, setIdeas] = useState<Idea[]>([]);
  const [clusters, setClusters] = useState<Cluster[]>([]);
  const [clusterMap, setClusterMap] = useState<ClusterMap>({});
  const [generating, setGenerating] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastGenerated, setLastGenerated] = useState<string | null>(null);

  useEffect(() => {
    async function load() {
      setLoading(true);
      try {
        const [ideasRes, clustersRes] = await Promise.all([
          fetch("/api/ideas"),
          fetch("/api/cluster"),
        ]);

        if (ideasRes.ok) {
          const data = await ideasRes.json();
          setIdeas(data.ideas ?? []);
        }

        if (clustersRes.ok) {
          const data = await clustersRes.json();
          if (data.clusters && data.clusters.length > 0) {
            const latest: Cluster = data.clusters[0];
            setClusters(data.clusters);
            // Rebuild map from latest cluster set
            // Each cluster row has name + idea_ids; rebuild display map
            const map: ClusterMap = {};
            data.clusters.forEach((c: Cluster) => {
              map[c.name] = c.idea_ids.map((id: string) => id);
            });
            setClusterMap(map);
            setLastGenerated(latest.generated_at);
          }
        }
      } finally {
        setLoading(false);
      }
    }
    load();
  }, []);

  async function handleCluster() {
    if (ideas.length < 2) {
      setError("Add at least 2 ideas to the wall before clustering.");
      return;
    }
    setGenerating(true);
    setError(null);

    try {
      const res = await fetch("/api/cluster", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ideas }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error ?? "Clustering failed");
      }

      const data = await res.json();
      setClusterMap(data.clusterMap ?? {});
      setLastGenerated(new Date().toISOString());
      // Reload saved clusters
      const clustersRes = await fetch("/api/cluster");
      if (clustersRes.ok) {
        const cData = await clustersRes.json();
        setClusters(cData.clusters ?? []);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong");
    } finally {
      setGenerating(false);
    }
  }

  async function handleRenameCluster(oldName: string, newName: string) {
    // Find the cluster row
    const cluster = clusters.find((c) => c.name === oldName);
    if (!cluster) return;

    // Update locally
    const newMap: ClusterMap = {};
    Object.entries(clusterMap).forEach(([k, v]) => {
      newMap[k === oldName ? newName : k] = v;
    });
    setClusterMap(newMap);

    // Persist
    await fetch(`/api/cluster`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id: cluster.id, name: newName }),
    });
  }

  // Build idea lookup map
  const ideaById: Record<string, Idea> = {};
  ideas.forEach((i) => {
    ideaById[i.id] = i;
  });

  const clusterEntries = Object.entries(clusterMap);
  const hasCluster = clusterEntries.length > 0;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end gap-4 justify-between mb-8">
        <div>
          <h1 className="text-2xl sm:text-3xl font-semibold text-ink tracking-tight">
            Cluster View
          </h1>
          <p className="text-sm text-ink/50 mt-1">
            Claude groups your ideas into thematic territories
          </p>
          {lastGenerated && (
            <p className="text-xs text-ink/35 mt-1">
              Last clustered{" "}
              {new Date(lastGenerated).toLocaleString("en-GB", {
                dateStyle: "medium",
                timeStyle: "short",
              })}
            </p>
          )}
        </div>

        <button
          onClick={handleCluster}
          disabled={generating || ideas.length < 2}
          className="btn-primary self-start sm:self-auto py-2.5 px-5 shrink-0"
        >
          {generating ? (
            <>
              <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              Clustering…
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
                  d="M9.75 3.104v5.714a2.25 2.25 0 01-.659 1.591L5 14.5M9.75 3.104c-.251.023-.501.05-.75.082m.75-.082a24.301 24.301 0 014.5 0m0 0v5.714c0 .597.237 1.17.659 1.591L19.8 15.3M14.25 3.104c.251.023.501.05.75.082M19.8 15.3l-1.57.393A9.065 9.065 0 0112 15a9.065 9.065 0 00-6.23-.693L5 14.5m14.8.8l1.402 1.402c1.232 1.232.65 3.318-1.067 3.611A48.309 48.309 0 0112 21c-2.773 0-5.491-.235-8.135-.687-1.718-.293-2.3-2.379-1.067-3.61L5 14.5"
                />
              </svg>
              Cluster my ideas
            </>
          )}
        </button>
      </div>

      {error && (
        <div className="bg-accent/10 border border-accent/20 rounded-xl px-4 py-3 mb-6 text-sm text-accent">
          {error}
        </div>
      )}

      {loading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {Array.from({ length: 4 }).map((_, i) => (
            <div key={i} className="space-y-3 animate-pulse">
              <div className="h-5 bg-paper-dark rounded w-2/3" />
              {Array.from({ length: 3 }).map((_, j) => (
                <div key={j} className="card p-3">
                  <div className="h-3 bg-paper-dark rounded w-full mb-2" />
                  <div className="h-3 bg-paper-dark rounded w-3/4" />
                </div>
              ))}
            </div>
          ))}
        </div>
      ) : !hasCluster ? (
        <div className="text-center py-20">
          <div className="w-16 h-16 bg-paper-dark rounded-2xl flex items-center justify-center mx-auto mb-5 text-2xl">
            ⬡
          </div>
          <h2 className="text-base font-semibold text-ink mb-2">
            No clusters yet
          </h2>
          <p className="text-sm text-ink/50 mb-6 max-w-sm mx-auto">
            Hit "Cluster my ideas" to have Claude group your ideas into thematic
            territories — like a TV commissioner mapping a slate.
          </p>
          <button
            onClick={handleCluster}
            disabled={generating || ideas.length < 2}
            className="btn-primary mx-auto"
          >
            {ideas.length < 2
              ? "Need at least 2 ideas first"
              : "Cluster my ideas"}
          </button>
        </div>
      ) : (
        <>
          {/* Re-cluster notice */}
          <div className="bg-paper-warm border border-paper-dark rounded-xl px-4 py-3 mb-6 flex items-center gap-3">
            <svg
              className="w-4 h-4 text-ink/40 shrink-0"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
              />
            </svg>
            <p className="text-xs text-ink/60">
              Re-clustering is non-destructive. Rename any cluster by clicking
              its title.
            </p>
          </div>

          {/* Cluster grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {clusterEntries.map(([name, ideaIds]) => {
              const clusterIdeas = ideaIds
                .map((id) => ideaById[id])
                .filter(Boolean);
              return (
                <ClusterGroup
                  key={name}
                  name={name}
                  ideas={clusterIdeas}
                  onRename={(newName) => handleRenameCluster(name, newName)}
                />
              );
            })}
          </div>

          {/* Unclustered */}
          {(() => {
            const clusteredIds = new Set(
              clusterEntries.flatMap(([, ids]) => ids)
            );
            const unclustered = ideas.filter((i) => !clusteredIds.has(i.id));
            if (unclustered.length === 0) return null;
            return (
              <div className="mt-8 pt-6 border-t border-paper-dark">
                <h3 className="text-sm font-medium text-ink/50 mb-4">
                  Unclustered ({unclustered.length})
                </h3>
                <div className="flex flex-wrap gap-2">
                  {unclustered.map((i) => (
                    <span
                      key={i.id}
                      className="text-xs bg-paper-dark text-ink/60 px-3 py-1.5 rounded-full"
                    >
                      {i.title}
                    </span>
                  ))}
                </div>
              </div>
            );
          })()}
        </>
      )}
    </div>
  );
}
