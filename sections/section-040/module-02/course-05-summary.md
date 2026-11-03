# Summary

Selections become text in a query, and the text must be valid for every choice the reader can make. This module built the multi-value version of the incident dashboard and the steps to debug it.

## What you learned

A variable that depends on a multi-value variable needs `=~` in its matcher, because several values are written as a group such as `(production|staging)`. A variable with `allowAllValue: true` and `customAllValue: ".*"` writes `.*` for `All`, which matches every value and keeps the query short. The `defaultValue` `$__all` starts the dropdown at `All`.

A `TextVariable` feeds a LogQL line filter. `|=` treats the text as plain, and `|~` treats it as a regular expression, where a bracket or a star can break the query; the `regex` format escapes those characters. A double quote in the text ends the string early. An empty field is valid and keeps every line.

TraceQL filters spans inside braces and joins conditions with `&&`. The built-in field `duration` compares with a number and a unit such as `100ms`. A static list of limits, with the unit in the value and words in the label, lets the reader choose the limit.

To debug a cascade, check the order of the variables, test each list by hand, test each panel query by hand with none, one, many and `All`, check the names, and check the scope.

- Use `=~` in every matcher that takes a variable that may have several values.
- Set `customAllValue` on every variable with `All` that feeds a regular expression.
- Prefer `|=` for free text in logs.
- Test the four cases before you share a dashboard.

<!-- astrona:playground:destroy -->
