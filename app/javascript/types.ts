export type Locale = "en" | "ja";

export interface Article {
  id: number;
  title_en: string;
  title_ja: string;
  published_at: string;
  source_url?: string | null;
  source?: string | null;
  source_title?: string | null;
  sentences?: Sentence[];
}

export interface Sentence {
  id: number;
  position: number;
  body_en: string;
  body_ja: string;
}

export function formatDate(dateString: string, locale: Locale): string {
  return new Date(dateString).toLocaleDateString(
    locale === "en" ? "en-US" : "ja-JP",
    { year: "numeric", month: "long", day: "numeric" }
  );
}
