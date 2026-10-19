# Fields

Give only the fields the request names, in the format it names. The fields are `slug`, `kind`, `intent`, `verb`, `state` and `purpose`, under those names when the format has keys and the request names none. `purpose` is the text after `so that`, without those two words, and keeps its `(guessed)` mark. Two efforts give two entries, such as two rows or a list of two.

"The one-liner" means the intent alone, as plain text. "A name" means the slug alone.

A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it: no explanation of the choices, no note on the guesses.
