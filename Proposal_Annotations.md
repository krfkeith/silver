## Motivation ##

We need a mechanism to solve the "location problem."  That is, some better handling of location information than the ad-hoc mess we have currently.  Annotations should fix this.  They might be more broadly applicable, but that remains to be seen.

Annotations introduce new information on undecorated trees, uniformly across all productions of a nonterminal.  This is certainly nice for location information, as the parser builds an undecorated tree, and location should be something that exists for all productions.

## Syntax ##

```
annotation location :: Location;
annotate Expr_C with location;
```

Declaring an annotation, and indicating what nonterminals are annotated.

In the future, we might consider adding "default values" for annotations. At this time we can simply ignore this possible feature, as it's not necessary for our initial purpose (location.)

Q: Should default values be on the `annotation`, or on the `annotate` declarations?
A: ???

Q: Why not mimic `occurs on` declarations?
A: I want to keep annotations and attributes as separate as possible in people's minds, so they are not confused.

```
addExpr(l.ast, r.ast, location=lhs.location)
```

Annotations are supplied at production invocation time, looking much like "optional parameters" in Python.  They are required to be at the end of the application, so you can't write `addExpr(location=lhs.location, l.ast, r.ast)` or anything like that.

Q: Why this syntax?
A: It would be familiar to any python programmers, as it basically does the same thing. No other special reason. Any different suggestions?

```
lhs.location
```

This accesses an annotation.  It will work on either an undecorated or decorated type.  (It would do the opposite of attributes, as this will implicitly undecorate a decorated tree.)

Q: Rascal has a special syntax for accessing an annotation, should we?
A: I don't think so.  Silver is already set up to figure out what is being asked with dot notation, so this is simple to code.  The only possible reason, in my opinion, to not use dot notation is that it overlaps with attributes, and we don't want to confuse newbies about annotations vs attributes.

## Further changes ##

The nonterminal `with` syntax should be extended to work with annotations, too.

```
nonterminal Expr with location, pp;
```

This shouldn't be too hard: it can just look up the name, and forward to the appropriate declaration.

We also need to worry about concrete syntax.  The copper translation needs to know how to supply `location`, but we also need to worry about making sure there aren't other annotations that it doesn't know how to supply!  We don't want the parser to generate invalid trees...  On the other hand, perhaps we DO want to allow annotations without default values, just by requiring that concrete productions provide a value for them!  This could get complicated, taken to its logical conclusion.  But we don't have to get there right away.

## Annotation vs Attribute ##

What's the difference?  Well, they couldn't be more different.  Annotations share more in common with children than they do with attributes.

You can think of an annotation as a child that:
  * Is common to all productions of a nonterminal.
  * Can be accessed directly from the "outside" (without pattern matching) using dot notation.
  * Is not listed explicitly in signatures.

Whereas attributes are:
  * Defined via equations, rather than supplied when a node is constructed.
  * Exist only the the decorated tree, instead of part of the undecorated tree.

## How to solve the location problem ##

We'd have a library.  Perhaps `silver:parse`.  Or maybe just put it straight in `core`.  In this library, we'd declare a `Location` type, and the `location` annotation.

In the copper translation, it would detect the `location` annotation, and automatically supply the appropriate `Location` value when constructing the parse tree node.

This would give us location information on all nodes, Silver-side, just by adding the annotation to your concrete nonterminals.  To pass it on to your ast, you'd have to add the annotation to your abstract nonterminals, and amend all your constructions of ast nodes to look like:

```
concrete production add_c
lhs::Expr_c ::= l::Expr_c  '+'  r::Expr_c
{
  lhs.ast = add(l.ast, r.ast, location=lhs.location);
}
```

Finally, we'd probably also change terminals, so instead of `line`, `column`, etc etc, they'd just have `location`.  This would simplify a lot of things.