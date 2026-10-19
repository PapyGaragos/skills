# Fields

Give only the fields the request names, in the format it names, one entry per property. The fields, under these names when the format has keys and the request names none:

- `property`: the property's name.
- `form`: the form the check takes, in a few plain words (`proof`, `test`, `CI check`, `script`, `LLM review`, `self-review`, `human decision`); the rung stays out.
- `to_write`: true when the check doesn't exist yet.
- `type`: `done`, `held` or `metric`, from the input's conditions.
- `conditions`: for `done` and `held`, the list of conditions as kept; `checked`: for `held`, when it is checked.
- `metric`, `now`, `better` and `ideal`: for `metric`, what is measured and how, its current value (`unknown` when not known), `lower` or `higher`, and the ideal when there is one.
- `proves`: what a pass proves, in one clause.
- `ground_with`: for checks on a judge or self-review, one check from a higher rung, with the same fields.
- `proxy`: for a human decision, the automated proxy when one exists.

A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it: no advice, no fallback plans.
