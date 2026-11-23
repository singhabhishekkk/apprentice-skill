# Capture in a JavaScript or TypeScript app

For an app that calls OpenAI Chat Completions through the `openai` npm package. The rules in
`SKILL.md` still hold: say where the data goes, wait for an explicit yes, keep the line in the
repo, and never capture secrets or personal data.

## Before you add anything

**Check it fits.** All of these must be true. If one is not, say which and stop.

- The call is `openai.chat.completions.create(...)`. The package does not record the
  Responses API, the Anthropic SDK or the Vercel AI SDK yet.
- The code runs on a server, with Node.js 22 or later (`node --version`). In a browser the
  hook passes the call through and records nothing.
- The request holds no secrets or personal data. The JavaScript package has no redact option
  yet, so if the payload may hold either, do not add the line.

**Say where the data goes, and wait.** Tell the user, in these words:

> Each call's input and output is sent to runapprentice.com and stored on your task there. I will add that only if you say yes.

Then add one line about scope, because the hook wraps the whole client: every Chat Completions
call made through that OpenAI client is recorded under one task, with the full request (the
messages, the tool definitions and the settings) and the full reply. It sends no request
headers, so the OpenAI key is not sent. If that client serves other jobs too, offer a separate
client for the repeated job. The yes rules in `SKILL.md` apply unchanged.

## Install the right package

The name is `runapprentice`. Write it exactly. Never guess another name: `apprentice` on npm
belongs to another party.

1. Check the current version first: `npm view runapprentice version`. Use what the registry
   says, not a number from this file.
2. Install with the project's own package manager. The lockfile tells you which:

   | Lockfile | Command |
   |---|---|
   | `package-lock.json` | `npm install runapprentice` |
   | `bun.lock` or `bun.lockb` | `bun add runapprentice` |
   | `pnpm-lock.yaml` | `pnpm add runapprentice` |
   | `yarn.lock` | `yarn add runapprentice` |
   | none | `npm install runapprentice` |

3. Confirm it is ours: `npm view runapprentice` lists the maintainer `singhabhishek` and the
   home page `https://runapprentice.com`. If it shows anything else, stop and tell the user.

## The line

Add `fetch` to the `new OpenAI(...)` call the app already has, and keep its other options:

```ts
import OpenAI from "openai";
import { captureFetch } from "runapprentice";

const openai = new OpenAI({ fetch: captureFetch({ task: "<task>" }) });
```

Then say which file changed, and that removing `fetch: captureFetch(...)` removes capture.

**The key.** The hook reads `APPRENTICE_API_KEY` from the server's environment. Put it there:
the server's `.env` (if the app loads one) or the host's secret settings. Never write the key
in code, never pass it as a literal `apiKey`, and never put it in a variable that ships to the
browser (such as `NEXT_PUBLIC_` or `VITE_`). Without a key the model call still works, nothing
is recorded, and the hook warns once with `capture_missing_key`.

**When Apprentice cannot be reached.** The model call never waits for an upload, and its
answer is unchanged. That call is not recorded, and the hook warns once with
`capture_delivery_failed`.

**Read every reply to the end**, streamed or not. A reply the app never finishes reading is not
recorded.

**Short scripts and serverless.** Uploads run in the background, and a process exit can lose
them. In a script that exits, keep the hook in a variable and wait for it before the end:

```ts
const capture = captureFetch({ task: "<task>" });
const openai = new OpenAI({ fetch: capture });
// ... the app's calls ...
await capture.flush();
```

If the server runtime offers `waitUntil`, pass it: `captureFetch({ task: "<task>", waitUntil })`.

## Check that a call was recorded

Do not stop at adding the line. Run one Chat Completions call through the hooked client, with
the user's OK if it spends money or touches production, and read the reply to the end. Then
read the counts from `await capture.flush()`:

| `flush()` returns | Meaning |
|---|---|
| `{}` | The call was recorded |
| `{ capture_missing_key: 1 }` | No key in that process's environment. Nothing was sent |
| any other code | Quote the warning the hook printed (`runapprentice [<code>] ...`) to the user |

`{}` means a recorded call only after a Chat Completions call went through the hook; with no
call, it is also `{}`. For a server, make one request to the endpoint and look for the call at
the link below instead.

Give the user the link `https://runapprentice.com/tasks/<task>/dataset`, where the call shows
as a raw row.

## What the JavaScript package does not do yet

- No `feedback`, upload or optimize calls, and no trace id is returned. Use the console, or the
  Python SDK and CLI, for those.
- Recorded calls land as raw rows, the same as captured Python calls. Once a person verifies
  them in the console, they optimize and train the same way, through the console or the
  Python CLI (`apprentice-train`).
