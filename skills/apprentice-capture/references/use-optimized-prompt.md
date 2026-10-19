# Use an optimized prompt in the user's code

This edit stays on the machine. Rendering the prompt does not send inputs or outputs to
runapprentice.com. Do not add `client.capture`, an upload, or a callback while doing it
unless the user has already been told that each call's input and output is sent there and
has said yes. Capture, when they want it, is a separate visible line they can delete.

`client.prompts.get(task).text` is instruction text: no input placeholder, often literal JSON
braces. `.format(...)` raises `KeyError`. `.replace(...)` can drop the input and ship a
prompt that never sees the user's data, with no error pointing at the missing field.

Use `prompts.get(task).messages(**inputs)`. It renders the message shape the backend recorded
when it scored that version. The keyword names are that artifact's `input_variables`: `input`
for a plain task, `question` and `context` for RAG, or the user's own names if a template was
registered.

The score describes that shape sent to the model in `report.detail["student_model"]`, with
`response_format={"type": "json_object"}` for JSON metrics (`text={"format": ...}` on the
Responses API). Say so rather than implying the number transfers to any model.
