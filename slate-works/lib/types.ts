export type IdeaStatus = "Raw" | "Developing" | "Parked";

export interface Idea {
  id: string;
  title: string;
  note: string | null;
  tags: string[] | null;
  status: IdeaStatus;
  votes: number;
  link: string | null;
  created_by: string | null;
  created_at: string;
  updated_at: string;
  comment_count?: number;
}

export interface Comment {
  id: string;
  idea_id: string;
  author: string | null;
  body: string;
  created_at: string;
}

export interface Cluster {
  id: string;
  name: string;
  idea_ids: string[];
  generated_at: string;
  is_manual_override: boolean;
}

export interface MorningBrief {
  id: string;
  generated_at: string;
  digest_json: DigestEntry[] | null;
  triggered_by: string | null;
}

export interface DigestEntry {
  title: string;
  publication: string;
  url: string;
  matched_idea_id: string | null;
  matched_idea_title: string | null;
  connection_note: string;
}

export interface TeamMember {
  id: string;
  name: string | null;
  email: string | null;
  avatar_colour: string | null;
}

export type SortOption = "date" | "votes" | "status";

export interface ClusterMap {
  [clusterName: string]: string[];
}
