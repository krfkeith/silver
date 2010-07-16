grammar silver:translation:java:concrete_syntax:copper;

import silver:definition:env;
import silver:definition:core;
import silver:util;

--------------------------------------------------------------------------------
-- Defs.sv

synthesized attribute lexerClassList :: [Decorated EnvItem] occurs on Defs;

aspect function unparseDefs
String ::= d_un::Defs
{
  dclinfos <- mapGetDcls(d.lexerClassList);
}

aspect production emptyDefs 
top::Defs ::= 
{
  top.lexerClassList = [];
}

aspect production appendDefs 
top::Defs ::= e1_un::Defs e2_un::Defs
{
  top.lexerClassList = e1.lexerClassList ++ e2.lexerClassList;
}

abstract production consLexerClassDef
top::Defs ::= d::Decorated EnvItem e2::Defs
{
  top.lexerClassList = d :: forward.lexerClassList;
  forwards to e2;
}

-- TODO: we don't do any renaming of lexer classes BUG

function addParserAttrDcl
Defs ::= sg::String sl::Decorated Location fn::String ty::Decorated TypeRep defs::Defs
{
  return consValueDef(defaultEnvItem(decorate parserAttrDcl(sg,sl,fn,ty) with {}), defs);
}

function addPluckTermDcl
Defs ::= sg::String sl::Decorated Location fn::String defs::Defs
{
  return consValueDef(defaultEnvItem(decorate pluckTermDcl(sg,sl,fn) with {}), defs);
}

function addLexerClassDcl
Defs ::= sg::String sl::Decorated Location fn::String tst::[String] td::[String] defs::Defs
{
  return consLexerClassDef(defaultEnvItem(decorate lexerClassDcl(sg,sl,fn, tst, td) with {}), defs);
}

function addTermAttrValueDcl
Defs ::= sg::String sl::Decorated Location fn::String ty::Decorated TypeRep defs::Defs
{
  return consValueDef(defaultEnvItem(decorate termAttrValueDcl(sg,sl,fn,ty) with {}), defs);
}

function addActionChildDcl
Defs ::= sg::String sl::Decorated Location fn::String ty::Decorated TypeRep defs::Defs
{
  return consValueDef(defaultEnvItem(decorate actionChildDcl(sg,sl,fn,ty) with {}), defs);
}

function addParserLocalDcl
Defs ::= sg::String sl::Decorated Location fn::String ty::Decorated TypeRep defs::Defs
{
  return consValueDef(defaultEnvItem(decorate parserLocalDcl(sg,sl,fn,ty) with {}), defs);
}

--------------------------------------------------------------------------------
-- Env.sv

synthesized attribute lexerClassTree :: Decorated EnvScope occurs on Env;

aspect production i_emptyEnv 
top::Env ::= 
{
  top.lexerClassTree = emptyEnvScope();
}

aspect production i_toEnv
top::Env ::= d_un::Defs
{
  top.lexerClassTree = oneEnvScope(buildTree(d.lexerClassList));
}

aspect production i_appendEnv
top::Env ::= e1::Decorated Env  e2::Decorated Env
{
  top.lexerClassTree = appendEnvScope(e1.lexerClassTree, e2.lexerClassTree);
}

aspect production i_newScopeEnv
top::Env ::= d_un::Defs  e::Decorated Env
{
  top.lexerClassTree = consEnvScope(buildTree(d.lexerClassList), e.lexerClassTree);
}

function getLexerClassDcl
[Decorated DclInfo] ::= search::String e::Decorated Env
{
  return searchEnvScope(search, e.lexerClassTree);
}

--------------------------------------------------------------------------------
-- QName.sv

aspect production qNameId
top::QName ::= id::Name
{
  top.lookupLexerClass = decorate customLookup("lexer class", getLexerClassDcl, top) with { env = top.env; };
}

aspect production qNameCons
top::QName ::= id::Name ':' qn::QName
{
  top.lookupLexerClass = decorate customLookup("lexer class", getLexerClassDcl, top) with { env = top.env; };
}

synthesized attribute lookupLexerClass :: Decorated QNameLookup occurs on QName;

