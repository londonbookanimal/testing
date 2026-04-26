import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { generateMorningBrief } from "@/lib/anthropic";
import { Idea } from "@/lib/types";

export async function POST(request: NextRequest) {
  const supabase = await createClient();
  const body = await request.json().catch(() => ({}));
  const { triggered_by = "manual" } = body;

  // Fetch all ideas
  const { data: ideas, error: ideasError } = await supabase
    .from("ideas")
    .select("*")
    .order("votes", { ascending: false });

  if (ideasError) {
    return NextResponse.json({ error: ideasError.message }, { status: 500 });
  }

  if (!ideas || ideas.length === 0) {
    return NextResponse.json(
      { error: "No ideas on the wall yet" },
      { status: 400 }
    );
  }

  let digest;
  try {
    digest = await generateMorningBrief(ideas as Idea[]);
  } catch (e) {
    console.error("Morning brief error:", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Brief generation failed" },
      { status: 500 }
    );
  }

  // Save to DB
  const { data: brief, error: saveError } = await supabase
    .from("morning_briefs")
    .insert({
      digest_json: digest,
      triggered_by,
    })
    .select()
    .single();

  if (saveError) {
    console.error("Brief save error:", saveError);
    // Return digest even if save fails
    return NextResponse.json({
      brief: {
        id: "unsaved",
        generated_at: new Date().toISOString(),
        digest_json: digest,
        triggered_by,
      },
    });
  }

  return NextResponse.json({ brief });
}

export async function GET() {
  const supabase = await createClient();

  const { data, error } = await supabase
    .from("morning_briefs")
    .select("*")
    .order("generated_at", { ascending: false })
    .limit(10);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ briefs: data ?? [] });
}
