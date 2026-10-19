---
name: apprentice-capture
description: >
  Use when a user explicitly asks to record LLM calls into an Apprentice
  dataset or to optimize a prompt: "capture my calls", "record traces",
  "log these to Apprentice", "optimize this prompt". Before adding any
  capture line or upload, tell the user that each call's input and output
  is sent to runapprentice.com and wait for an explicit yes. Never add
  capture silently. The line stays visible in the repo and comes out by
  deleting it. Never capture secrets or personal data (PII). Delegate
  fine-tuning to apprentice-train and serving to apprentice-deploy.
license: MIT
---

# Capture calls and optimize the prompt

Capture is opt-in. Noticing a repeatable call, or the user agreeing that a task looks expensive, is not permission to record it.

## Say where the data goes, and wait

Before you add a capture line, upload rows, or run anything that sends model inputs and outputs off the machine, tell the user this in plain words:

> Each call's input and output is sent to runapprentice.com and stored on your task there. I will add that only if you say yes.

Wait for an explicit yes. Naming the feature ("capture my calls", "record these") is not that yes. The yes is a reply after you have said that each call's input and output is sent to runapprentice.com. If their request already says that, repeat it in one line, name the file you will change, and treat that request as the yes. Silence, "maybe", or moving on to another task is a no. Do not add the line, do not upload, and do not send the data from a one-off script instead.

Never capture secrets or personal data (PII): API keys, tokens, passwords, session cookies, account or government identifiers, health details, or similar. If the payload may contain any of that, stop and say so before asking for the yes. Redact only if the user asks, and show them what would still be sent.

## Pick the path after they say yes

| What the user said | What to use |
|---|---|
| Yes, send inputs and outputs, and it is a Python app | **SDK.** Add the capture line in the repo, then hand back the console link |
| "I don't want to sign in", "keep it local", "no account" | **CLI** `--local`, the user's own OpenAI key. Rows stay on this machine and are not sent to runapprentice.com |
| "Just optimize this prompt", rows already exist, and they agreed to any upload this step needs | **SDK.** Upload, then run |
| Already in the console | Send a deep link. Do not add capture |

Ask when they have not chosen. That choice decides whether inputs and outputs leave the machine.

The SDK is the hosted path because it returns real values instead of text to parse. The CLI is for the no-account case.

Do not mix the two in one piece of work. A session that used the SDK for uploads and the CLI for status checks left the user unable to tell which interface had done what.

## Add the line in the repo, where they can see it

Only after the yes. One line beside the existing model call, in the file that already makes that call. Then say which file changed, and that deleting that one line removes capture.

```python
from runapprentice import Apprentice

client = Apprentice(api_key=os.environ["APPRENTICE_API_KEY"])
trace_id = client.capture(task="duplicate-search", input=question, output=answer)
```

If runapprentice.com cannot be reached, `capture` does not raise. The app keeps running, the model call's own answer is unchanged, and this call is not recorded. The return value is `None`. Say that when you add the line. The point is that a capture problem cannot take the user's endpoint down.

Leave the line in the repository so it shows up in review and the user can remove it by deleting it. Do not record calls from a throwaway script (under `/tmp` or anywhere else) and then delete the script. Once that file is gone, nothing in the repo shows that inputs and outputs were sent, and the user cannot switch capture off by deleting a line. A real session did this: eight `/tmp` scripts, zero repo changes, and a dataset stuck at six rows with no record of how they were collected. If they only wanted a one-time upload of rows they already have, say that, upload after they agree, and do not leave a recorder behind.

### Framework-specific capture

Same rule: name runapprentice.com and the fields that will be sent, and wait for a yes, before adding a callback or wrapper.

- LangChain: `ApprenticeCallback` records calls and simple retriever context and sends them to runapprentice.com.
  [Guide](https://docs.runapprentice.com/how-to/capture-langchain). Use manual `capture(...)`
  when there are several retrievers or custom context formatting.
- Raw OpenAI clients, Chat Completions and Responses:
  [guide](https://docs.runapprentice.com/how-to/capture-openai).
- Full method list: [Python SDK reference](https://docs.runapprentice.com/reference/python-sdk).

Two API details worth getting right, both from the docs' rules for coding agents: upload with
`client.datasets.upload(...)`, since there is no `ingest()` method, and pass structured
`inputs={...}` for a multi-field or templated task rather than one rendered prompt string. For
RAG, `inputs={"question": question, "context": exact_context}`, where the context is exactly
what the model saw. An upload sends those fields to runapprentice.com and needs the same yes as `capture`.

## Feedback is what makes drift measurable

Capture records the call. Feedback records whether it worked, and that score is what the
console's Drift view charts and what decides when a retrain is worth doing. Feedback is sent
to runapprentice.com as well. Add it only after the same yes.

```python
if trace_id:                              # None when this call was not recorded; the app still ran
    client.feedback(trace_id, good=True)  # or good=False, or score=0.4
```

**Never manufacture it.** Do not add a second LLM call to grade the first, and do not infer
"looked fine" from confidence or length. A guessed score retrains the model on a lie. With no
real signal, add nothing: captured rows still become gold when a human verifies them.

## Optimize

Run this when the user asks to optimize, using rows already in their account or rows they just agreed to upload.

```python
job = client.optimize("duplicate-search").wait()
```

Hosted optimize needs **20 verified rows**, counting gold plus silver. Below that it refuses,
and the fix is verification, not more uploading.

For the no-account case, with the user's own OpenAI key:

```
apprentice optimize <task> --local --data examples.csv
```

Local optimize is scored as JSON extraction only, so every output must be a JSON object or
array; the CLI refuses other data before spending anything. Note also what the console shows:
`optimize --local` is never recorded there, so that run stays on the machine that ran it.
It does not send the rows to runapprentice.com.

## Hand back the link, every time

| Page | URL |
|---|---|
| Rows and tiers | `https://runapprentice.com/tasks/<task>/dataset` |
| Review queue | `https://runapprentice.com/tasks/<task>/review` |
| Runs | `https://runapprentice.com/tasks/<task>/runs` |
| Send to an expert | `https://runapprentice.com/tasks/<task>/collaborators` |

Say what is waiting there, not just the address: "6 rows uploaded as silver, verify them at
`https://runapprentice.com/tasks/duplicate-search/review`".

## An API key cannot make rows gold, and the two paths do not land in the same place

Uploaded rows land as **silver**. Captured traces land as **raw**, which is one step further
back: raw counts for nothing until a human reviews it, while silver already counts toward
optimize. Recording a verdict needs a signed-in console session either way, so a key-only
workflow can never promote either kind.

That matters because the two features count differently: **optimize uses gold plus silver,
training uses gold only**. So a user who uploads rows can optimize immediately and can never
train; a user who only captures cannot even optimize until the traces are reviewed. Say which
one applies at the moment the rows land, not when the user hits a threshold, and link the
review page so it is one click to fix.

Do not auto-approve rows to gold to clear a threshold. Gold means a human checked it, and a
model grading its own output is not that.

## After a run finishes

Read `references/use-optimized-prompt.md` when the user asks to put the optimized prompt in
their code. That edit stays on the machine: it renders a prompt locally and does not send
inputs or outputs anywhere. Do not add a capture line in the same edit unless they already
gave the yes above. The artifact is not a template. `.format()` on it raises `KeyError`, and
a string replace can drop the input so the prompt ships without the user's data.

## Sandbox

`Operation not permitted` on a network call means the sandbox denied it, so the request never
left the machine. A bare connection error is weaker evidence and has other causes (DNS, TLS, a
proxy, a firewall, an outage), so name the sandbox as one possibility rather than the answer.
Claude Code and Codex sandboxes deny network by default; tell the user what to enable rather
than retrying or working around it. Do not bypass the sandbox to send inputs and outputs out.
