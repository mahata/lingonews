import { readStdin, parseTimeoutMs, extractJson, runCopilotSession } from "./lib/copilot_helpers";

const BASE_SYSTEM_PROMPT = `You are a bilingual news summarizer. You receive a Japanese news article and produce a structured bilingual (English/Japanese) summary.

Your output must be valid JSON with this exact structure:
{
  "title_en": "English translation of the article title",
  "title_ja": "Original Japanese title (cleaned up if needed)",
  "sentences": [
    { "body_en": "English sentence", "body_ja": "Japanese sentence" },
    ...
  ]
}

Rules:
- The number of sentence pairs should reflect the article's length and complexity (typically 3-8 pairs)
- Each sentence pair should capture a key point from the article
- English sentences should be natural, not literal translations
- Japanese sentences should preserve the original meaning faithfully
- Output ONLY the JSON object, no markdown fences, no extra text
- Ensure the output is valid, parseable JSON. Double-check that all strings are properly escaped and all brackets are closed.`;

const RESEARCH_ADDENDUM = `

Additional context from web research has been provided alongside the article. Incorporate relevant findings from the research to produce a richer, more informed summary. Prioritize the original article's content but enhance it with background, context, and related developments from the research.`;

interface SummaryOutput {
  title_en: string;
  title_ja: string;
  sentences: Array<{ body_en: string; body_ja: string }>;
}

async function main(): Promise<void> {
  const title = process.argv[2];
  if (!title) {
    console.error("Usage: npx tsx script/summarize_article.ts <title>");
    console.error("Article text is read from stdin.");
    process.exit(1);
  }

  const articleText = await readStdin();
  if (!articleText) {
    console.error("Error: No article text provided on stdin.");
    process.exit(1);
  }

  const researchContext = process.env.RESEARCH_CONTEXT || "";
  const systemPrompt = researchContext
    ? BASE_SYSTEM_PROMPT + RESEARCH_ADDENDUM
    : BASE_SYSTEM_PROMPT;

  let prompt = `Here is a Japanese news article. Title: "${title}"\n\nArticle text:\n${articleText}`;
  if (researchContext) {
    prompt += `\n\nWeb research findings:\n${researchContext}`;
  }
  prompt += `\n\nPlease produce the bilingual summary JSON.`;

  const timeoutMs = parseTimeoutMs(process.env.SUMMARIZE_TIMEOUT_MS);

  const rawResponse = await runCopilotSession({ systemMessage: systemPrompt, prompt, timeoutMs });

  const parsed = extractJson(rawResponse) as SummaryOutput;
  if (!parsed.title_en || !parsed.title_ja || !Array.isArray(parsed.sentences)) {
    console.error("Raw LLM response:", rawResponse);
    throw new Error("Invalid response structure: missing title_en, title_ja, or sentences");
  }

  console.log(JSON.stringify(parsed));
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
