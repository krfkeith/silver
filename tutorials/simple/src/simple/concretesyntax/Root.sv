grammar simple:concretesyntax;

exports simple:terminals;

{- "imports" statements import constructs from the specified grammars
 - into ALL FILES in this grammar.
 - Thus "import" (no s) statements for these grammars
 - are not needed (or allowed) in other files in this grammar.
 -}
imports silver:langutil;
imports simple:abstractsyntax as ast;
imports silver:langutil:location;


{--
 - The concrete syntax represent a complete Simple program.
 -}
closed nonterminal Root with unparse, silver:langutil:location:location, ast<ast:Root>;

{- The use of ast<...> above is a "parameterized attribute"
 - The 'ast' attribute is declared in silver:langutil.
 -
 - 'ast:Root' is the nonterminal Root from our abstract syntax.
 - it is accessed via the namespace 'ast' because we used "as ast"
 - in the imports like above. This prefixes every name imported from that
 - grammar. The colon is Silver's namespace resolution operator.
 -}


concrete productions r::Root
 | 'main' '(' ')' '{' s::Stmts '}'  { r.unparse = "main () {\n" ++ s.unparse ++ "}\n";
                                      -- We're again about to use the 'ast' namespace to refer to rootStmt in
                                      -- our abstractsyntax:
                                      r.ast = ast:rootStmt(s.ast); }

{-
concrete production rootStmt
r::Root ::= 'main' '(' ')' '{' s::Stmts '}'
{
  r.unparse = "main () {\n" ++ s.unparse ++ "}\n";
  -- We're again about to use the 'ast' namespace to refer to rootStmt in
  -- our abstractsyntax:
  r.ast = ast:rootStmt(s.ast);
}
-}
