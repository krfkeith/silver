# Organization #

There are a few obvious things that need to be documented:

  * Install guide
  * Use of Silver. Command line arguments, for example.
  * Every piece of syntax, in reference style.  I suggest organizing this _primarily_ by (AgDcl/ProductionStmt/Expr) and then allowing labels to take any other cross-cutting view. These pages should probably be prefixed with "Reference" e.g. Reference\_Function, Reference\_Nonterminal.
  * A lot more explanation of underlying concepts.  Attribute grammars, especially with some of the modern features, are... different.  Decorated vs Undecorated, for example, usually requires some explanation.  The section documenting forwarding may be extensive, considering that's basically our thing.  Some things to include: (Maybe prefix all these with Guide)
    * Dec/undec
    * forwarding
    * aspects / collection attributes
    * module system behavior
    * types
    * Auto decoration and decoration behavior
    * IO
    * (add anything else!)
  * Standard libraries.  **For the moment, let's omit this.**  My plan is to get a SilverDoc extension working that can generate these pages from the doc comments in the libraries themselves.
  * Tutorial-style documentation.  e.g. the tutorial grammars.  **We should consider doing some sort of Literate Silver thing for this, so the doc and code are maintained together.** (Maybe prefix all these with Tutorial)
    * Generally, this should be how people get started with Silver. The above should all be in _reference_ style, this should be in explanatory style.
  * Style guide documentation. I am opinionated!
  * We should create a bibliography wiki page, to point all the refs to. (Note: for MELT people, the refs in the raw latex can be found in /papers/bibs/ in svn.) **This would also be a good opportunity to start creating an annotated bibliography!**

Also, there will be a FAQ.  There are a couple obvious things to put in there right now.

As a reminder at least to me, we should consider importing all the bugzilla issues to this issue tracker.  I think this one is nicer!

# Labels #

A list of labels to be created for the documentation in the wiki:

  * AgDeclaration  (for all top-level declarations)
  * ProductionStatement  (for all constructs inside curly braces in productions)
  * Expression  (for all expression syntax)
  * ConcreteSyntax  (for all top-level declarations that are specific to concrete syntax)
  * CopperSpecific  (for all ... that are specific to copper)
  * for each extensions (easy terminal, autocopy, etc)
  * Types (for all built-in types and structures)
  * Attributes (local, production, inherited, synthesized, ...)


Add any more labels that are even _potentially_ useful to this list, before we begin!