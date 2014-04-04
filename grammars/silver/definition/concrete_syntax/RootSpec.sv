grammar silver:definition:concrete_syntax;

import silver:driver:util;

attribute syntaxAst, parserSpecs occurs on RootSpec, ModuleExportedDefs, Grammar;

aspect function unparseRootSpec
String ::= r::Decorated RootSpec
{
  unparses <- ["syntax [" ++ implode(",\n ", foldr(consSyntax, nilSyntax(), r.syntaxAst).unparses) ++ "]"];
  unparses <- ["parsers [" ++ implode(",\n ", map((.unparse), r.parserSpecs)) ++ "]"];
}

aspect production errorRootSpec
top::RootSpec ::= _ _ _ _
{
  top.syntaxAst = [];
  top.parserSpecs = [];
}

aspect production grammarRootSpec
top::RootSpec ::= c1::Grammar  _ _ _
{
  top.syntaxAst = c1.syntaxAst;
  top.parserSpecs = c1.parserSpecs;
}

aspect production nilGrammar
top::Grammar ::=
{
  top.syntaxAst = [];
  top.parserSpecs = [];
}

aspect production consGrammar
top::Grammar ::= c1::Root  c2::Grammar
{
  top.syntaxAst = c1.syntaxAst ++ c2.syntaxAst;
  top.parserSpecs = c1.parserSpecs ++ c2.parserSpecs;
}

aspect production moduleExportedDefs
top::ModuleExportedDefs ::= l::Location  compiled::EnvTree<Decorated RootSpec>  grammarDependencies::[String]  need::[String]  seen::[String]
{
  top.syntaxAst = if null(need) || null(rs) then [] else (head(rs).syntaxAst ++ recurse.syntaxAst);
  top.parserSpecs = if null(need) || null(rs) then [] else (head(rs).parserSpecs ++ recurse.parserSpecs);
}


