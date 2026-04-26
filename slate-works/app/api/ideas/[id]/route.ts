import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

interface RouteParams {
  params: { id: string };
}

export async function PATCH(request: NextRequest, { params }: RouteParams) {
  const supabase = await createClient();
  const body = await request.json();
  const { action, status, votes } = body;

  if (action === "vote") {
    // Atomic increment
    const { data: current } = await supabase
      .from("ideas")
      .select("votes")
      .eq("id", params.id)
      .single();

    if (!current) {
      return NextResponse.json({ error: "Idea not found" }, { status: 404 });
    }

    const { data, error } = await supabase
      .from("ideas")
      .update({ votes: (current.votes ?? 0) + 1 })
      .eq("id", params.id)
      .select("votes")
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ votes: data.votes });
  }

  if (action === "status") {
    const allowed = ["Raw", "Developing", "Parked"];
    if (!allowed.includes(status)) {
      return NextResponse.json({ error: "Invalid status" }, { status: 400 });
    }

    const { data, error } = await supabase
      .from("ideas")
      .update({ status })
      .eq("id", params.id)
      .select()
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ idea: data });
  }

  // Generic update
  const updates: Record<string, unknown> = {};
  if (status !== undefined) updates.status = status;
  if (votes !== undefined) updates.votes = votes;

  const { data, error } = await supabase
    .from("ideas")
    .update(updates)
    .eq("id", params.id)
    .select()
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ idea: data });
}

export async function DELETE(_request: NextRequest, { params }: RouteParams) {
  const supabase = await createClient();

  const { error } = await supabase
    .from("ideas")
    .delete()
    .eq("id", params.id);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ success: true });
}
