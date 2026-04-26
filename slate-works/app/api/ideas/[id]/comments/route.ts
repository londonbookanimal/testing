import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

interface RouteParams {
  params: { id: string };
}

export async function GET(_request: NextRequest, { params }: RouteParams) {
  const supabase = await createClient();

  const { data: comments, error } = await supabase
    .from("comments")
    .select("*")
    .eq("idea_id", params.id)
    .order("created_at", { ascending: true });

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ comments: comments ?? [] });
}

export async function POST(request: NextRequest, { params }: RouteParams) {
  const supabase = await createClient();
  const body = await request.json();

  const { body: commentBody, author } = body;

  if (!commentBody || typeof commentBody !== "string" || !commentBody.trim()) {
    return NextResponse.json(
      { error: "Comment body is required" },
      { status: 400 }
    );
  }

  const { data, error } = await supabase
    .from("comments")
    .insert({
      idea_id: params.id,
      body: commentBody.trim(),
      author: author ?? null,
    })
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ comment: data }, { status: 201 });
}
