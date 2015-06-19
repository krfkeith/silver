## IDE declarations ##

The basic IDE declaration should take the form:

```
ide "Silver" ".sv" rParse;
```

We should extend this with utilities to provide certain features:

```
ide "Silver" ".sv" rParse {
  something = Expr,
  blah = Expr
}
```

## Coloring ##

Fonts are declared as follows:

```
font fontName color(r#,g#,b#) style;
font keyword color(0,0,255) bold;
font comment color(0,255,0) italic;
font type color(0,0,255);
```

Colorings for terminals are declared as follows:

```
terminal For 'for' color = keyword;
ignore terminal Comment /\-\-.*/ color = comment;
```

Or via lexer classes:

```
lexer class KEYWORD color = keyword;
terminal While 'while' lexer classes { KEYWORD };
```

These are simply ignored for normal parser generation, and only have meaning when we generate a new parser specific to the IDE. (we don't use `rParse` directly, we generate a new parser based on the `rParse` specification.)

No further changes to the ide declaration are necessary, these take effect automatically.

## Building ##

Builders will have the following form:

```
function svBuilder
IOVal<[silver:langutil:Message]> ::= delta::[File]  ioin::IO
{ ... }

ide "Silver" ".sv" rParse {
  builder = svBuilder
}
```

Builders are executed when the user requests a build explicitly, or after a user saves a file (if incremental building is turned on.)

TODO: Do we need a special `File` type?  Or will strings do?  Dunno...

ALSO TODO: We need to standardize on `Message` and `Location` types for this to work out okay.

## Analyzing ##

Purely responsible for turning a (undecorated) concrete syntax tree (obtained straight from the parser) into whatever tree should be used for analysis.  Typically this is the decorated abstract syntax tree.
function svAnalyzer
IOVal<Decorated Root> ::= tree::Root  ioin::IO
{ ... }

ide "Silver" ".sv" rParse {
  analyzer = svAnalyzer
}

Typing: The input type of `tree` is whatever the starting nonterminal of `rParse` is.  The ouput type can be ANYTHING!  The remaining functions, however, MUST take the same input type the analyzer produces.

This is an IO function because it conceivably needs to get info from external sources somehow...

== Error reporting ==

Although build handles building / error reporting when files are saved, we also must support reporting errors as a file is typed.  Parse errors are already handled automatically, we must only be concerned with semantic errors.  That is the purpose of this function.

{{{
function svErrors
[Message] ::= tree::Decorated Root
{ ... }

ide "Silver" ".sv" rParse {
  analyzer = svAnalyzer,
  errors = svErrors
}
}}}

This function's input type is the same type that the analyzer produces.  Here again, we need a standardized `Message` and `Location` types for this to work.

== Outlining ==

To produce the outline view of a file, we just produce a suitable data structure.

{{{
function svOutliner
Outline ::= tree::Decorated Root
{ ... }

ide "Silver" ".sv" rParse {
  analyzer = svAnalyzer,
  outliner = svOutliner
}
}}}

This needs a standardized `Outline` type.

== Collapsing ==

This looks identical to Outliner.  The result type is `[Collapsible]` where we need to define some standardized `Collapsible` type.  Or maybe that's just a `Location`???



TODO continue...```