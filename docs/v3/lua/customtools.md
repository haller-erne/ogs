
### Simplified API
The simplified custom tool API uses four states and associated transitions to implement the tool behaviour. Each transitions can be implemented in the custom tool LUA code to provide the custom functionality - if not implemented, the transition is executed without a custom action.

Here is the state diagram for the behaviour:

``` mermaid
stateDiagram-v2
    [*] --> Running: init()
    state Running {
      inactive --> active: activate()
      active --> inactive: deactivate()
      active --> enabled: enable()
      enabled --> enabled: execute()
      enabled --> disabled: disable()
      disabled --> enabled: enable()
      disabled --> inactive: deactivate()
    }
```

### Mermaid test

The following is a simple mermaid sequence diagram, for more details, see [https://squidfunk.github.io/mkdocs-material/reference/diagrams/](https://squidfunk.github.io/mkdocs-material/reference/diagrams/)

``` mermaid
sequenceDiagram
  autonumber
  Alice->>John: Hello John, how are you?
  loop Healthcheck
      John->>John: Fight against hypochondria
  end
  Note right of John: Rational thoughts!
  John-->>Alice: Great!
  John->>Bob: How about you?
  Bob-->>John: Jolly good!
```
