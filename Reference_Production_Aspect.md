
```
aspect production plus
top::Expr ::= l::Expr  r::Expr
{
}
```

See also more general documentation on aspects [Concept\_Aspects](Concept_Aspects.md).

## Syntax ##

Aspects permit attribute equations to be written separately from wherever the production was originally defined.

Aspects are permitted to omit referencing children using an underscore (`_`), but must otherwise repeat the type of each child, as a basic sanity check (and local documentation). The names of the RHS children and LHS can differ from the original production declaration.

```
aspect production plus
top::Expr ::= _ _
{
  top.isLiteral = false;
}
```