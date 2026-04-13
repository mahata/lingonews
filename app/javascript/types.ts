export type Locale = "en" | "ja";

export interface Article {
  id: number;
  title_en: string;
  title_ja: string;
  published_at: string;
  sentences?: Sentence[];
}

export interface Sentence {
  id: number;
  position: number;
  body_en: string;
  body_ja: string;
}
