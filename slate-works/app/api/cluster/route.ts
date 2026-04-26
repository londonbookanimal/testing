import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { clusterIdeas } from "@/lib/anthropic";
import { Idea } from "@/lib/types";

export async function GET() {
  const supabase = await createClient();

  const { data: clusters, error } = await supabase
    .from("clusters")
    .select("*")
    .order("generated_at", { ascending: false })
    .limit(50);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ clusters: clusters ?? [] });
}

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const body = await request.json();
  const { ideas }: { ideas: Idea[] } = body;

  if (!ideas || ideas.length < 2) {
    return NextResponse.json(
      { error: "Provide at least 2 ideas to cluster" },
      { status: 400 }
    );
  }

  let clusterMap: Record<string, string[]>;
  try {
    clusterMap = await clusterIdeas(ideas);
  } catch (e) {
    console.error("Cluster error:", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Clustering failed" },
      { status: 500 }
    );
  }

  // Save each cluster as a row
  const rows = Object.entries(clusterMap).map(([name, idea_ids]) => ({
    name,
    idea_ids,
    is_manual_override: false,
  }));

  if (rows.length > 0) {
    const { error: insertError } = await supabase
      .from("clusters")
      .insert(rows);

    if (insertError) {
      console.error("Cluster save error:", insertError);
      // Don't fail — return the map anyway
    }
  }

  return NextResponse.json({ clusterMap });
}

export async function PATCH(request: NextRequest) {
  const supabase = await createClient();
  const body = await request.json();
  const { id, name } = body;

  if (!id || !name) {
    return NextResponse.json({ error: "id and name required" }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("clusters")
    .update({ name, is_manual_override: true })
    .eq("id", id)
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ cluster: data });
}
