import Anthropic from "@anthropic-ai/sdk";
import { Idea, ClusterMap, DigestEntry } from "./types";

export const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const MODEL = "claude-sonnet-4-5-20251001";

const CLUSTER_SYSTEM_PROMPT =
  "You are a documentary and factual TV development assistant. Group the following ideas into thematic clusters. Return only valid JSON: { \"ClusterName\": [\"idea_id_1\", \"idea_id_2\"] }. Use 4–8 clusters. Name them as a TV commissioner would.";

export async function clusterIdeas(ideas: Idea[]): Promise<ClusterMap> {
  const ideaList = ideas
    .map((i) => `ID: ${i.id}\nTitle: ${i.title}\nNote: ${i.note ?? ""}`)
    .join("\n\n---\n\n");

  const message = await anthropic.messages.create({
    model: MODEL,
    max_tokens: 2048,
    system: CLUSTER_SYSTEM_PROMPT,
    messages: [
      {
        role: "user",
        content: `Here are the ideas to cluster:\n\n${ideaList}`,
      },
    ],
  });

  const text = message.content
    .filter((b) => b.type === "text")
    .map((b) => (b as { type: "text"; text: string }).text)
    .join("");

  // Extract JSON from the response (handle markdown code blocks)
  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/) ||
    text.match(/(\{[\s\S]*\})/);

  if (!jsonMatch) {
    throw new Error("No valid JSON found in cluster response");
  }

  return JSON.parse(jsonMatch[1]) as ClusterMap;
}

export async function generateMorningBrief(
  ideas: Idea[]
): Promise<DigestEntry[]> {
  const ideaSummary = ideas
    .slice(0, 20) // limit context
    .map((i) => `ID: ${i.id} | Title: "${i.title}" | Note: ${i.note ?? ""}`)
    .join("\n");

  const publications = [
    "The Guardian",
    "The New York Times",
    "The Atlantic",
    "The New Yorker",
    "BBC News",
  ];

  const prompt = `You are a researcher for a documentary production company called The Slate Works.

Here are our current ideas in development:
${ideaSummary}

Please search each of these publications for stories published in the last 48 hours that connect to any of our ideas above:
${publications.join(", ")}

For each relevant story you find, return a JSON array with this structure:
[
  {
    "title": "Story headline",
    "publication": "Publication name",
    "url": "Full URL to the story",
    "matched_idea_id": "the idea UUID it matches, or null",
    "matched_idea_title": "the idea title it matches, or null",
    "connection_note": "One sentence explaining why this story is relevant to the matched idea"
  }
]

Return only the JSON array, no other text. Find 5–10 of the most relevant stories. If a story doesn't match any idea well, skip it.`;

  const message = await anthropic.messages.create({
    model: MODEL,
    max_tokens: 4096,
    tools: [
      {
        type: "web_search_20250305" as const,
        name: "web_search",
      } as Parameters<typeof anthropic.messages.create>[0]["tools"] extends
        | (infer T)[]
        | undefined
        ? T
        : never,
    ],
    messages: [
      {
        role: "user",
        content: prompt,
      },
    ],
  });

  // Collect all text blocks from the final response
  const text = message.content
    .filter((b) => b.type === "text")
    .map((b) => (b as { type: "text"; text: string }).text)
    .join("");

  const jsonMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/) ||
    text.match(/(\[[\s\S]*\])/);

  if (!jsonMatch) {
    return [];
  }

  try {
    return JSON.parse(jsonMatch[1]) as DigestEntry[];
  } catch {
    return [];
  }
}
