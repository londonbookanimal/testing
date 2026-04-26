import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();

  const { data: ideas, error } = await supabase
    .from("ideas")
    .select(
      `
      *,
      comment_count:comments(count)
    `
    )
    .order("created_at", { ascending: false });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // Flatten comment count from [{count: N}] to a number
  const normalized = (ideas ?? []).map((idea) => ({
    ...idea,
    comment_count: Array.isArray(idea.comment_count)
      ? (idea.comment_count[0] as { count: number })?.count ?? 0
      : 0,
  }));

  return NextResponse.json({ ideas: normalized });
}

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const body = await request.json();

  const { title, note, tags, status, link, created_by } = body;

  if (!title || typeof title !== "string" || !title.trim()) {
    return NextResponse.json({ error: "Title is required" }, { status: 400 });
  }

  const { data, error } = await supabase
    .from("ideas")
    .insert({
      title: title.trim(),
      note: note ?? null,
      tags: tags ?? null,
      status: status ?? "Raw",
      link: link ?? null,
      created_by: created_by ?? null,
      votes: 0,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ idea: data }, { status: 201 });
}
