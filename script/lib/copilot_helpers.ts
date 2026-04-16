import { CopilotClient, approveAll } from "@github/copilot-sdk";

export async function readStdin(): Promise<string> {
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf-8").trim();
}

export function parseTimeoutMs(envValue: string | undefined, defaultMs: number = 300000): number {
  const parsed = parseInt(envValue || "", 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : defaultMs;
}

export function extractJson(raw: string): unknown {
  let jsonStr = raw.trim();
  const fenceMatch = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) {
    jsonStr = fenceMatch[1].trim();
  }

  const firstBrace = jsonStr.indexOf("{");
  const lastBrace = jsonStr.lastIndexOf("}");
  if (firstBrace !== -1 && lastBrace > firstBrace) {
    jsonStr = jsonStr.substring(firstBrace, lastBrace + 1);
  }

  return JSON.parse(jsonStr);
}

interface RunSessionOptions {
  systemMessage: string;
  prompt: string;
  timeoutMs: number;
}

export async function runCopilotSession({ systemMessage, prompt, timeoutMs }: RunSessionOptions): Promise<string> {
  const client = new CopilotClient();

  try {
    await client.start();

    const session = await client.createSession({
      onPermissionRequest: approveAll,
      systemMessage: { content: systemMessage },
    });

    let fullResponse = "";
    let timeout: ReturnType<typeof setTimeout> | undefined;

    const done = new Promise<void>((resolve, reject) => {
      timeout = setTimeout(() => {
        reject(new Error(`Copilot SDK session timed out after ${timeoutMs / 1000} seconds`));
      }, timeoutMs);

      session.on("assistant.message", (event) => {
        fullResponse += event.data.content;
      });

      session.on("session.idle", () => {
        clearTimeout(timeout);
        resolve();
      });
    });

    try {
      await session.send({ prompt });
      await done;
    } finally {
      clearTimeout(timeout);
      await session.disconnect();
    }

    return fullResponse;
  } finally {
    await client.stop();
  }
}
