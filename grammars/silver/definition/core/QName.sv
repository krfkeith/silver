grammar silver:definition:core;

{--
 - Qualified names of the form 'a:b:c:d...'
 -}
nonterminal QName with name, location, grammarName, file, env, pp;
{--
 - Qualified names where the LAST name has an upper case first letter.
 -}
nonterminal QNameUpper with name, location, grammarName, file, env, pp;
{--
 - Qualified names with an optional type list following it.
 -}
nonterminal QNameWithTL with location, grammarName, file, env, pp, qname, typelist;

synthesized attribute qname :: Decorated QName;
synthesized attribute typelist :: Decorated TypeList;
synthesized attribute dcls :: [Decorated DclInfo];

function qName
QName ::= l::Decorated Location s::String
{
  return qNameId(nameIdLower(terminal(IdLower_t, s, l.line, l.column)));
}

concrete production qNameId
top::QName ::= id::Name
{
  top.name = id.name;
  top.pp = id.pp;
  top.location = id.location;
  
  top.lookupValue = decorate customLookup("value", getValueDcl, top.name, top.location) with { env = top.env; };
  top.lookupType = decorate customLookup("type", getTypeDcl, top.name, top.location) with { env = top.env; };
  top.lookupAttribute = decorate customLookup("attribute", getAttrDcl, top.name, top.location) with { env = top.env; };
}

concrete production qNameCons
top::QName ::= id::Name ':' qn::QName
{
  top.name = id.name ++ ":" ++ qn.name;
  top.pp = id.pp ++ ":" ++ qn.pp;
  top.location = loc(top.file, $2.line, $2.column);
  
  top.lookupValue = decorate customLookup("value", getValueDcl, top.name, top.location) with { env = top.env; };
  top.lookupType = decorate customLookup("type", getTypeDcl, top.name, top.location) with { env = top.env; };
  top.lookupAttribute = decorate customLookup("attribute", getAttrDcl, top.name, top.location) with { env = top.env; };
}

nonterminal QNameLookup with fullName, typerep, errors, env, dcls, dcl, dclBoundVars;

synthesized attribute lookupValue :: Decorated QNameLookup occurs on QName;
synthesized attribute lookupType :: Decorated QNameLookup occurs on QName;
synthesized attribute lookupAttribute :: Decorated QNameLookup occurs on QName;

abstract production customLookup
top::QNameLookup ::= kindOfLookup::String lookupFunc::Function([Decorated DclInfo] ::= String Decorated Env) name::String l::Decorated Location 
{
  top.dcls = lookupFunc(name, top.env);
  top.dcl = if null(top.dcls) then error("INTERNAL ERROR: Accessing dcl of " ++ kindOfLookup ++ " " ++ name ++ " at " ++ l.unparse)
            else head(top.dcls);
  
  top.fullName = if null(top.dcls) then "undeclared:value:" ++ name
                 else top.dcl.fullName;
  
  top.typerep = if null(top.dcls) then errorType()  else top.dcl.typerep;
  top.dclBoundVars = if null(top.dcls) then []      else top.dcl.dclBoundVars;
  
  top.errors := (if null(top.dcls)
                  then [err(l, "Undeclared " ++ kindOfLookup ++ " '" ++ name ++ "'.")]
                  else [])
             ++ (if length(top.dcls) > 1
                  then [err(l, "Ambiguous reference to " ++ kindOfLookup ++ " '" ++ name ++ "'. Possibilities are:\n" ++ printPossibilities(top.dcls))] 
                  else []);
}

function printPossibilities
String ::= lst::[Decorated DclInfo]
{
  local attribute dcl :: Decorated DclInfo;
  dcl = head(lst);
  
  -- TODO: perhaps some way of including types, when they are relevant (attributes, values)
  return if null(lst) then ""
         else ("\t" ++ dcl.fullName ++ " (" ++ dcl.sourceLocation.fileName ++ ":" ++ toString(dcl.sourceLocation.line) ++ ")\n")
              ++ printPossibilities(tail(lst));
}


---- Right now, this is only used for types:
attribute lookupType occurs on QNameUpper;

concrete production qNameUpperId
top::QNameUpper ::= id::IdUpper_t
{
  top.name = id.lexeme;
  top.pp = id.lexeme;
  top.location = loc(top.file, id.line, id.column);
  
  top.lookupType = decorate customLookup("type", getTypeDcl, top.name, top.location) with { env = top.env; };
}

concrete production qNameUpperCons
top::QNameUpper ::= id::Name ':' qn::QNameUpper
{
  top.name = id.name ++ ":" ++ qn.name;
  top.pp = id.pp ++ ":" ++ qn.pp;
  top.location = loc(top.file, $2.line, $2.column);
  
  top.lookupType = decorate customLookup("type", getTypeDcl, top.name, top.location) with { env = top.env; };
}



concrete production qNameWithoutTL
top::QNameWithTL ::= q::QName
{
  top.pp = q.pp;
  forwards to qNameWithTL(q, '<', typeListNone(), '>');
}
concrete production qNameWithTL
top::QNameWithTL ::= q::QName '<' tl::TypeList '>'
{
  top.pp = q.pp ++ "<" ++ tl.pp ++ ">";
  top.location = q.location;
  top.qname = q;
  top.typelist = tl;
}


