import { CopilotClient, approveAll } from "@github/copilot-sdk";

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

async function main(): Promise<void> {
  const title = process.argv[2];
  if (!title) {
    console.error(
      "Usage: npx tsx script/research_topic.ts <title>\nArticle text is read from stdin."
    );
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

    const prompt = `Here is a Japanese news article. Please research this topic on the web and provide additional context.\n\nTitle: "${title}"\n\nArticle text:\n${articleText}\n\nPlease search the web for related information and produce the research context JSON.`;

    await session.send({ prompt });
    await done;
    await session.disconnect();

    let jsonStr = fullResponse.trim();
    const fenceMatch = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (fenceMatch) {
      jsonStr = fenceMatch[1].trim();
    }

    const firstBrace = jsonStr.indexOf("{");
    const lastBrace = jsonStr.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      jsonStr = jsonStr.substring(firstBrace, lastBrace + 1);
    }

    const parsed = JSON.parse(jsonStr);
    if (!parsed.research_context || typeof parsed.research_context !== "string") {
      console.error("Raw LLM response:", fullResponse);
      throw new Error(
        "Invalid response structure: missing or invalid research_context"
      );
    }

    console.log(JSON.stringify(parsed));
  } finally {
    await client.stop();
  }
}

main().catch((err) => {
  console.error(`Error: ${err.message}`);
  process.exit(1);
});
