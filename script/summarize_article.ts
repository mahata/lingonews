import { CopilotClient, approveAll } from "@github/copilot-sdk";

const SYSTEM_PROMPT = `You are a bilingual news summarizer. You receive a Japanese news article and produce a structured bilingual (English/Japanese) summary.

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

async function main(): Promise<void> {
  const title = process.argv[2];
  if (!title) {
    console.error("Usage: npx tsx script/summarize_article.ts <title>");
    console.error("Article text is read from stdin.");
    process.exit(1);
  }

  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const articleText = Buffer.concat(chunks).toString("utf-8").trim();

  if (!articleText) {
    console.error("Error: No article text provided on stdin.");
    process.exit(1);
  }

  const client = new CopilotClient();

  try {
    await client.start();

    const session = await client.createSession({
      onPermissionRequest: approveAll,
      systemMessage: { content: SYSTEM_PROMPT },
    });

    let fullResponse = "";

    const done = new Promise<void>((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error("Copilot SDK session timed out after 120 seconds"));
      }, 120_000);

      session.on("assistant.message", (event) => {
        fullResponse += event.data.content;
      });

      session.on("session.idle", () => {
        clearTimeout(timeout);
        resolve();
      });
    });

    const prompt = `Here is a Japanese news article. Title: "${title}"\n\nArticle text:\n${articleText}\n\nPlease produce the bilingual summary JSON.`;

    await session.send({ prompt });
    await done;
    await session.disconnect();

    // Extract JSON from response (handle potential markdown fences)
    let jsonStr = fullResponse.trim();
    const fenceMatch = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (fenceMatch) {
      jsonStr = fenceMatch[1].trim();
    }

    // Strip any text outside the JSON object (e.g., LLM preamble/postamble)
    const firstBrace = jsonStr.indexOf("{");
    const lastBrace = jsonStr.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      jsonStr = jsonStr.substring(firstBrace, lastBrace + 1);
    }

    // Validate it's parseable JSON
    const parsed = JSON.parse(jsonStr);
    if (!parsed.title_en || !parsed.title_ja || !Array.isArray(parsed.sentences)) {
      console.error("Raw LLM response:", fullResponse);
      throw new Error("Invalid response structure: missing title_en, title_ja, or sentences");
    }

    // Output clean JSON to stdout
    console.log(JSON.stringify(parsed));
  } finally {
    await client.stop();
  }
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
