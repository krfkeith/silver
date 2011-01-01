grammar silver:modification:autocopyattr;

import silver:util;
import silver:definition:core;
import silver:definition:env;
import silver:definition:type:syntax;
import silver:definition:type;

terminal AutoCopy_kwd 'autocopy' lexer classes {KEYWORD};

concrete production attributeDclAutoEmpty
top::AGDcl ::= 'autocopy' 'attribute' a::Name '::' te::Type ';'
{
  forwards to attributeDclAuto($1,$2,a,'<',typeListNone(),'>', $4, te, $6);
}

concrete production attributeDclAuto
top::AGDcl ::= 'autocopy' 'attribute' a::Name '<' tl::TypeList '>' '::' te::Type ';'
{
  top.pp = "autocopy attribute " ++ a.pp ++ " :: " ++ te.pp ++ ";";
  top.location = loc(top.file, $1.line, $1.column);

  production attribute fName :: String;
  fName = top.grammarName ++ ":" ++ a.name;

  top.defs = addAutocopyDcl(top.grammarName, a.location, fName, tl.freeVariables, te.typerep, emptyDefs());

--------
  tl.env = newScopeEnv( addNewLexicalTyVars(top.grammarName, top.location, tl.lexicalTypeVariables),
                        top.env);
  te.env = tl.env;
  top.errors <- if containsDuplicates(tl.lexicalTypeVariables)
                then [err(top.location, "Duplicate type variable names listed")]
                else [];
  top.errors <- tl.errorsTyVars;
--------
  
  top.errors <-
        if length(getAttrDcl(fName, top.env)) > 1
        then [err(top.location, "Attribute '" ++ fName ++ "' is already bound.")]
        else [];
  
  -- AUTOCOPY IS UNSOUND OTHERWISE
  -- We don't know just from the "occurs on" bit whether the types are the same and its safe to autocopy, so...
  top.errors <-
        if !null(tl.types)
        then [err(top.location, "Autocopy attributes cannot be parameterized by type variables!")]
        else [];

  top.errors := te.errors;
  
  forwards to attributeDclInh(terminal(Inherited_kwd, "inherited", $1), $2, a, $4, tl, $6, $7, te, $9);
}

