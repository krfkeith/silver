grammar silver:modification:ffi;
imports silver:definition:core;
imports silver:definition:env;
imports silver:definition:type;
imports silver:definition:type:syntax;
imports silver:util;

terminal Type_kwd 'type'; -- no keyword class...

-- TODO: this should provide some sort of translation type
-- but right now, we don't. Phooey.

-- TODO: uhhh 'nonterminal foreign type' is a dumb declaration. fix this

concrete production ffiTypeDcl
top::AGDcl ::= 'nonterminal' 'foreign' 'type' id::Name botl::BracketedOptTypeList ';' -- '{' ffidefs::FFIDefs '}'
{
  top.pp = "nonterminal foreign type " ++ id.pp ++ botl.pp ++ ";"; -- "{\n" ++ ffidefs.pp ++ "}";
  top.location = loc(top.file, $1.line, $1.column);
  
  production attribute fName :: String;
  fName = top.grammarName ++ ":" ++ id.name;

  production attribute tl :: Decorated TypeList;
  tl = botl.typelist;

  -- TODO: this is horrifying. ntDcls are actually generic "add a new named type"
  -- but, given their name, that's not obvious.
  -- We should either rename them, or add a new 'ftDcl' or something.
  top.defs = addNtDcl(top.grammarName, id.location, fName, tl.freeVariables, foreignTypeExp(fName, tl.types), emptyDefs());

  top.errors := tl.errors;
  
  -- Put the variables listed on the rhs in the environment FOR TL ONLY, so they're all "declared"
  botl.env = newScopeEnv( addNewLexicalTyVars(top.grammarName, top.location, tl.lexicalTypeVariables),
                        top.env);
  top.errors <- if containsDuplicates(tl.lexicalTypeVariables)
                then [err(top.location, "Duplicate type variable names listed")]
                else [];
  
  -- Make sure only type variables show up in the tl
  top.errors <- tl.errorsTyVars;
  
  -- Redefinition check of the name
  top.errors <- 
       if length(getTypeDcl(fName, top.env)) > 1 
       then [err(top.location, "Type '" ++ fName ++ "' is already bound.")]
       else [];

  top.errors <-
       if isLower(substring(0,1,id.name))
       then [err(id.location, "Types must be capitalized. Invalid foreign type name " ++ id.name)]
       else [];

  forwards to agDclDefault();
}

