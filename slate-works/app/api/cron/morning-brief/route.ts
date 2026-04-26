import { NextRequest, NextResponse } from "next/server";
import { createServiceClient } from "@/lib/supabase/server";
import { generateMorningBrief } from "@/lib/anthropic";
import { Idea } from "@/lib/types";

export async function GET(request: NextRequest) {
  // Verify cron secret
  const authHeader = request.headers.get("authorization");
  const expected = `Bearer ${process.env.CRON_SECRET}`;

  if (!process.env.CRON_SECRET || authHeader !== expected) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Use service client to bypass RLS (cron has no user session)
  const supabase = await createServiceClient();

  const { data: ideas, error: ideasError } = await supabase
    .from("ideas")
    .select("*")
    .order("votes", { ascending: false });

  if (ideasError) {
    return NextResponse.json({ error: ideasError.message }, { status: 500 });
  }

  if (!ideas || ideas.length === 0) {
    return NextResponse.json(
      { message: "No ideas — skipping brief" },
      { status: 200 }
    );
  }

  let digest;
  try {
    digest = await generateMorningBrief(ideas as Idea[]);
  } catch (e) {
    console.error("Cron morning brief error:", e);
    return NextResponse.json(
      { error: e instanceof Error ? e.message : "Brief generation failed" },
      { status: 500 }
    );
  }

  const { error: saveError } = await supabase.from("morning_briefs").insert({
    digest_json: digest,
    triggered_by: "cron",
  });

  if (saveError) {
    console.error("Cron brief save error:", saveError);
  }

  return NextResponse.json({
    success: true,
    entriesFound: digest.length,
    triggeredAt: new Date().toISOString(),
  });
}
