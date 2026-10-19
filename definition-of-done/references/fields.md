# Fields

Give only the fields the request names, in the format it names, one entry per property. The fields are:

- `property`: the property's name.
- `type`: `done`, `held` or `metric`, from the kind's shape in step 3.
- `conditions`: for `done` and `held`, the list of conditions.
- `metric`: for `metric`, what is measured and over what period.
- `better`: for `metric`, `lower` or `higher`.
- `ideal`: for `metric`, only when there is one.

Use those names when the format has keys and the request names none. A `(guessed)` mark stays in the text it marks.

A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it: no preamble, no advice, no note on the guesses.
