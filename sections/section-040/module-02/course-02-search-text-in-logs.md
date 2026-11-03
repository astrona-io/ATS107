# Search Text In Logs

A log table with the right streams is still a long list. The reader wants to type a word and see the lines that contain it. In LogQL, a line filter after the stream selector does that, and a `TextVariable` holds the word.

## The line filters

| Filter | Keeps the lines that | Example |
| --- | --- | --- |
| `\|= "text"` | Contain the text | `\|= "order"` |
| `!= "text"` | Do not contain the text | `!= "debug"` |
| `\|~ "pattern"` | Match the regular expression | `\|~ "order.*payments"` |
| `!~ "pattern"` | Do not match the regular expression | `!~ "debug\|trace"` |

A filter belongs after the selector in the same query: `{service_name="checkout"} |= "order"`. Filters run in order, and each one narrows the result of the one before.

## A text variable for the filter

A `TextVariable` is a text field. Its `value` is the starting text, and `constant: false` lets the reader change it. Add this variable to the list in `dashboard-explorer.yaml`, after `service`:

<!-- astrona:playground:renew -->

```yaml
    - kind: TextVariable
      spec:
        name: search
        display:
          name: Search
          hidden: false
        value: order
        constant: false
```

Then change the query of the panel `logs` so that it filters on the text:

```yaml
                  query: '{deployment_environment=~"$env", service_name=~"$service"} |= "$search"'
```

Apply the file again with `percli apply -f dashboard-explorer.yaml`. The field `Search` appears with the text `order`, and the table shows the lines `order handled by checkout` and `order handled by payments`. Type `payments` and press Enter: only the lines of the second service remain.

## Plain text or a pattern

With `|= "$search"` the text is plain. A search for `a.b` finds the three characters `a.b` and nothing else. With `|~ "$search"` the text is a regular expression. A search for `a.b` also finds `axb`, and a search for `(` is an invalid expression, so Loki rejects the query and the table is empty.

Choose by who will use the field. For a field that people type words in, use `|=`. For a field meant for patterns, use `|~`, and tell the reader in the display name, such as `Search (regular expression)`.

If you must use `|~` and want plain-text behaviour, use the `regex` format, which escapes the characters that have a meaning in a regular expression:

```yaml
                  query: '{deployment_environment=~"$env", service_name=~"$service"} |~ "${search:regex}"'
```

## Quotes and an empty field

A value with a double quote ends the string in the query early, and the query is invalid. A reader who types `say "hi"` breaks the panel. The format `doublequote` does not help, as it adds quotes around the value. When quotes are likely, restrict the field to a list of choices with a `ListVariable` instead of a free text field.

An empty field is valid. `|= ""` keeps every line, so a cleared search field shows all lines again.

## Common pitfalls

> [!WARNING]
> - **`|~ "$search"` with free text.** A reader who types a bracket or a star sees an empty table with no explanation.
> - **A filter before the selector.** `|= "order" {service_name="checkout"}` is not valid LogQL. The selector comes first.
> - **A search for text that is a label, not a log line.** A line filter reads the body of the line. To filter on a label such as the service, use the selector.
