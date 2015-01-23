grammar silver:definition:env;

synthesized attribute unparse :: String;

{--
 - Surround every element of a [String] with single quotes.
 -}
function quoteStrings
[String] ::= s::[String]
{
  return map(quoteString, s);
}

{--
 - Turns a String into a string that can be parsed with IName.
 -}
function quoteString
String ::= s::String
{
  return "'" ++ s ++ "'";
}

{--
 - Turns a [String] into a string that can be parsed with INames.
 -}
function unparseStrings
String ::= s::[String]
{
  return "[" ++ implode(", ", quoteStrings(s)) ++ "]";
}

{--
 - A helper for unparsing lists.
 -}
function unparseNonStrings
String ::= s::[String]
{
  return "[" ++ implode(",", s) ++ "]";
}

{--
 - Turn a list of types into a string that can be parsed with ITypeReps.
 -}
function unparseTypes
String ::= tes::[TypeExp] bv::[TyVar]
{
  return "[" ++ implode(", ", mapUnparseTypes(tes, bv)) ++ "]";
}

{--
 - HELPER: must exist because of the bv parameter. Can't map until partial application is here.
 -}
function mapUnparseTypes
[String] ::= tes::[TypeExp] bv::[TyVar]
{
  local fst :: TypeExp = head(tes);
  fst.boundVariables = bv;
  
  return if null(tes) then []
         else fst.unparse :: mapUnparseTypes(tail(tes), bv);
}

{--
 - Turn a list of type variables into a string that can be parser with ITyVarDcls.
 -}
function unparseTyVars
String ::= utvs::[TyVar]  bv::[TyVar]
{
  return "[" ++ implode(", ", mapUnparseTyVars(utvs, bv)) ++ "]";
}

{--
 - HELPER: must exist because of the bv parameter.
 -}
function mapUnparseTyVars
[String] ::= tes::[TyVar]  bv::[TyVar]
{
  return if null(tes) then []
         else findAbbrevFor(head(tes), bv) :: mapUnparseTyVars(tail(tes), bv);
}

{--
 - Turn a list of signature elements into a string can can be parsed by INamedSignatureElements.
 -}
function unparseSignatureElements
String ::= s::[NamedSignatureElement] bv::[TyVar]
{
  return "[" ++ unparseSignatureElementsHelp(s, bv) ++ "]";
}

{--
 - HELPR: must exist because of the bv parameter.
 -}
function unparseSignatureElementsHelp
String ::= s::[NamedSignatureElement] bv::[TyVar]
{
  local h :: NamedSignatureElement = head(s);
  h.boundVariables = bv;

  return if null(s) then "" else h.unparse ++ (if null(tail(s)) then "" else (", " ++ unparseSignatureElementsHelp(tail(s), bv)));
}

{--
 - Escape all back-slashes, then the quotes.
 -}
function escapeString
String ::= s::String
{
  return substitute("\"", "\\\"", substitute("\\", "\\\\", s));
}
function unescapeString
String ::= s::String
{
  return substitute("\\\\", "\\", substitute("\\\"", "\"", s));
}

