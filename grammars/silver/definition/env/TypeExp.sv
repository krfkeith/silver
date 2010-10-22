grammar silver:definition:env;
import silver:definition:type;
import silver:util;

-- Just to clarify:
-- call prettyType to pretty print the type.
-- get typeName to find out what nonterminal a NT or DNT is
-- call unparseType to put something into an interface file

attribute unparse, typeName occurs on TypeExp;

synthesized attribute typeName :: String;

aspect production defaultTypeExp
top::TypeExp ::=
{
  top.typeName = ""; -- We actually put a value here, since it's possible for us to request typeName of nonsensical things.
}

aspect production varTypeExp
top::TypeExp ::= tv::TyVar
{
  top.unparse = findAbbrevFor(tv, top.boundVariables);
}

aspect production skolemTypeExp
top::TypeExp ::= tv::TyVar
{
  top.unparse = findAbbrevFor(tv, top.boundVariables);
}

aspect production intTypeExp
top::TypeExp ::=
{
  top.unparse = "int";
}

aspect production boolTypeExp
top::TypeExp ::=
{
  top.unparse = "bool" ;
}

aspect production floatTypeExp
top::TypeExp ::=
{
  top.unparse = "float" ;
}

aspect production stringTypeExp
top::TypeExp ::=
{
  top.unparse = "string" ;
}

aspect production nonterminalTypeExp
top::TypeExp ::= fn::String params::[TypeExp]
{
  top.unparse = "nt('" ++ fn ++ "', " ++ unparseTypes(params, top.boundVariables) ++ ")"; -- TODO 
  top.typeName = fn;
}

aspect production terminalTypeExp
top::TypeExp ::= fn::String
{
  top.unparse = "term('" ++ fn ++ "')";
  top.typeName = fn;
}

aspect production decoratedTypeExp
top::TypeExp ::= te::TypeExp
{
  top.unparse = "decorated(" ++ te.unparse ++ ")" ;
  top.typeName = te.typeName;
}

aspect production functionTypeExp
top::TypeExp ::= out::TypeExp params::[TypeExp]
{
  top.unparse = "fun(" ++ unparseTypes(params, top.boundVariables) ++ ", " ++ out.unparse ++ ")"  ;
}

aspect production productionTypeExp
top::TypeExp ::= out::TypeExp params::[TypeExp]
{
  top.unparse = "prod(" ++ unparseTypes(params, top.boundVariables) ++ ", " ++ out.unparse ++ ")"  ;
}

function unparseTypes
String ::= tes::[TypeExp] bv::[TyVar]
{
  return "[" ++ folds(", ", mapUnparseTypes(tes, bv)) ++ "]";
}
function mapUnparseTypes
[String] ::= tes::[TypeExp] bv::[TyVar]
{
  local attribute fst :: TypeExp;
  fst = head(tes);
  fst.boundVariables = bv;
  
  return if null(tes) then []
         else fst.unparse :: mapUnparseTypes(tail(tes), bv);
}


function unparseTyVars
String ::= utvs::[TyVar]  bv::[TyVar]
{
  return "[" ++ folds(", ", mapUnparseTyVars(utvs, bv)) ++ "]";
}
function mapUnparseTyVars
[String] ::= tes::[TyVar]  bv::[TyVar]
{
  return if null(tes) then []
         else findAbbrevFor(head(tes), bv) :: mapUnparseTyVars(tail(tes), bv);
}

