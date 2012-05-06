grammar silver:modification:collection;

import silver:definition:env;
import silver:definition:core;
import silver:definition:type;

attribute attrBaseDefDispatcher, attrAppendDefDispatcher, baseDefDispatcher, appendDefDispatcher occurs on DclInfo;

synthesized attribute attrBaseDefDispatcher :: (ProductionStmt ::= DefLHS Dot_t Decorated QName Equal_t Expr);
synthesized attribute attrAppendDefDispatcher :: (ProductionStmt ::= DefLHS Dot_t Decorated QName Equal_t Expr);

synthesized attribute baseDefDispatcher :: (ProductionStmt ::= Decorated QName  Equal_t  Expr);
synthesized attribute appendDefDispatcher :: (ProductionStmt ::= Decorated QName  Equal_t  Expr);

-- TODO: the 'operation' value on these declarations is never used.
-- Please take a moment to think about whether it should even exist or not.

aspect default production
top::DclInfo ::=
{
  top.attrBaseDefDispatcher = errorCollectionDefDispatcher;
  top.attrAppendDefDispatcher = errorCollectionDefDispatcher;

  top.baseDefDispatcher = errorCollectionValueDef;
  top.appendDefDispatcher = errorCollectionValueDef;
}

abstract production synCollectionDcl
top::DclInfo ::= sg::String sl::Location fn::String bound::[TyVar] ty::TypeExp o::Operation
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  ty.boundVariables = top.boundVariables ++ bound; -- explicit to make sure it errors if we can't
  top.unparse = "syncol(" ++ sl.unparse ++ ", '" ++ fn ++ "', " ++ unparseTyVars(bound, ty.boundVariables) ++ ", " ++ ty.unparse ++ ", " ++ o.unparse ++ ")";
  
  top.typerep = ty;
  top.dclBoundVars = bound;

  top.attrAccessDispatcher = synDNTAccessDispatcher;
  top.attrDefDispatcher = errorColNormalAttributeDef;

  top.attrBaseDefDispatcher = synBaseColAttributeDef;
  top.attrAppendDefDispatcher = synAppendColAttributeDef;

  forwards to synDcl(sg,sl,fn,bound,ty);
}
abstract production inhCollectionDcl
top::DclInfo ::= sg::String sl::Location fn::String bound::[TyVar] ty::TypeExp o::Operation
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  ty.boundVariables = top.boundVariables ++ bound; -- explicit to make sure it errors if we can't
  top.unparse = "inhcol(" ++ sl.unparse ++ ", '" ++ fn ++ "', " ++ unparseTyVars(bound, ty.boundVariables) ++ ", " ++ ty.unparse ++ ", " ++ o.unparse ++ ")";
  
  top.typerep = ty;
  top.dclBoundVars = bound;

  top.attrAccessDispatcher = inhDNTAccessDispatcher;
  top.attrDefDispatcher = errorColNormalAttributeDef;

  top.attrBaseDefDispatcher = inhBaseColAttributeDef;
  top.attrAppendDefDispatcher = inhAppendColAttributeDef;

  forwards to inhDcl(sg,sl,fn,bound,ty);
}

abstract production localCollectionDcl
top::DclInfo ::= sg::String sl::Location fn::String ty::TypeExp o::Operation
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  ty.boundVariables = top.boundVariables; -- explicit to make sure it errors if we can't
  top.unparse = "loccol(" ++ sl.unparse ++ ", '" ++ fn ++ "', " ++ ty.unparse ++ ", " ++ o.unparse ++ ")";
  
  top.typerep = ty;
  
  top.refDispatcher = localReference;
  top.defDispatcher = errorColNormalValueDef;
  top.defLHSDispatcher = localDefLHS;

  top.baseDefDispatcher = baseCollectionValueDef;
  top.appendDefDispatcher = appendCollectionValueDef;

  forwards to localDcl(sg,sl,fn,ty);
  
  top.substitutedDclInfo = localCollectionDcl(sg,sl,fn, performSubstitution(ty, top.givenSubstitution), o);
}


-- Defs
function addSynColDcl
Defs ::= sg::String sl::Location fn::String bound::[TyVar] ty::TypeExp o::Operation defs::Defs
{
  return consAttrDef(defaultEnvItem(decorate synCollectionDcl(sg,sl,fn,bound,ty,o) with {}), defs);
}
function addInhColDcl
Defs ::= sg::String sl::Location fn::String bound::[TyVar] ty::TypeExp o::Operation defs::Defs
{
  return consAttrDef(defaultEnvItem(decorate inhCollectionDcl(sg,sl,fn,bound,ty,o) with {}), defs);
}
function addLocalColDcl
Defs ::= sg::String sl::Location fn::String ty::TypeExp o::Operation defs::Defs
{
  return consValueDef(defaultEnvItem(decorate localCollectionDcl(sg,sl,fn,ty,o) with {}), defs);
}

