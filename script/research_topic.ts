import { readStdin, parseTimeoutMs, extractJson, runCopilotSession } from "./lib/copilot_helpers";

const SYSTEM_PROMPT = `You are a bilingual research assistant. You receive a Japanese news article title and text. Your job is to research the topic on the web and provide additional context, background information, and related developments.

Rules:
- Use your web search tools to find relevant, recent information about the topic
- Focus on facts, context, and background that would enrich understanding of the news
- Include both English and Japanese sources if available
- Provide a concise research summary (3-5 paragraphs)
- Output ONLY a JSON object with this exact structure:
{
  "research_context": "Your research findings as a single string with paragraph breaks"
}
- Output ONLY the JSON object, no markdown fences, no extra text
- Ensure the output is valid, parseable JSON. Double-check that all strings are properly escaped and all brackets are closed.`;

interface ResearchOutput {
  research_context: string;
}

async function main(): Promise<void> {
  const title = process.argv[2];
  if (!title) {
    console.error(
      "Usage: npx tsx script/research_topic.ts <title>\nArticle text is read from stdin."
    );
    process.exit(1);
  }

  const articleText = await readStdin();
  if (!articleText) {
    console.error("Error: No article text provided on stdin.");
    process.exit(1);
  }

  const prompt = `Here is a Japanese news article. Please research this topic on the web and provide additional context.\n\nTitle: "${title}"\n\nArticle text:\n${articleText}\n\nPlease search the web for related information and produce the research context JSON.`;

  const timeoutMs = parseTimeoutMs(process.env.RESEARCH_TIMEOUT_MS);

  const rawResponse = await runCopilotSession({ systemMessage: SYSTEM_PROMPT, prompt, timeoutMs });

  const parsed = extractJson(rawResponse) as ResearchOutput;
  if (!parsed.research_context || typeof parsed.research_context !== "string") {
    console.error("Raw LLM response:", rawResponse);
    throw new Error(
      "Invalid response structure: missing or invalid research_context"
    );
  }

  console.log(JSON.stringify(parsed));
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
