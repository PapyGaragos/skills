# Fields

Give only the fields the request names, in the format it names, one entry per question. The fields are:

- `question`: the question as sharpened in step 1.
- `kind`: `what is` or `what is wanted`.
- `verdict`: `answered`, `unconfirmed` or `ask`.
- `answer`: for `answered` and `unconfirmed`, the answer or the best one so far.
- `rung` and `where`: for `answered` and `unconfirmed`, the rung that gave the answer and where exactly.
- `settled_by`: for `unconfirmed`, the rung that would settle it.
- `ask_whom` and `ask_question`: for `ask`, `a person` or `a stronger model`, and the question standing on its own.
- `found`: for `ask`, a list of what each lower rung gave, each with its `rung` and `where`; empty when nothing did.

Use those names when the format has keys and the request names none.

A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it: no preamble, no advice.
