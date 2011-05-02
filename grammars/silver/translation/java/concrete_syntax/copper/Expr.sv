grammar silver:translation:java:concrete_syntax:copper;

abstract production actionChildReference
top::Expr ::= q::Decorated QName
{
  top.pp = q.pp; 
  top.location = q.location;

  top.errors := []; -- Should only ever be in scope when valid

  top.typerep = q.lookupValue.typerep;

  top.translation = "((" ++ q.lookupValue.typerep.transType ++ ")((common.Node)RESULT).getChild(" ++ makeClassName(top.signature.fullName) ++ ".i_" ++ q.lookupValue.fullName ++ "))";

  top.upSubst = top.downSubst;
  
  forwards to defaultExpr();
}

abstract production pluckTerminalReference
top::Expr ::= q::Decorated QName
{
  top.pp = q.pp; 
  top.location = q.location;

  top.errors := []; -- Should only be referenceable from a context where its valid.

  top.typerep = errorType(); -- TODO: BUG: Need a real type here (AnyTerminalType or something)
  
  top.translation = makeCopperName(q.lookupValue.fullName); -- Value right here?
  
  top.upSubst = top.downSubst;
  
  forwards to defaultExpr();
}

abstract production disambigLexemeReference
top::Expr ::= q::Decorated QName
{
  top.pp = q.pp; 
  top.location = q.location;

  top.errors := []; -- Should only ever be in scope when valid

  top.typerep = stringTypeExp();
  
  top.translation = "new common.StringCatter(lexeme)";
  
  top.upSubst = top.downSubst;
  
  forwards to defaultExpr();
}

abstract production parserAttributeReference
top::Expr ::= q::Decorated QName
{
  top.pp = q.pp; 
  top.location = q.location;

  top.errors := if !top.blockContext.permitActions
                then [err(top.location, "References to parser attributes can only be made in action blocks")]
                else [];

  top.typerep = q.lookupValue.typerep;

  top.translation = makeCopperName(q.lookupValue.fullName);

  top.upSubst = top.downSubst;
  
  forwards to defaultExpr();
}

abstract production termAttrValueReference
top::Expr ::= q::Decorated QName
{
  top.pp = q.pp; 
  top.location = q.location;

  top.errors := []; -- Should only ever be in scope in action blocks

  top.typerep = q.lookupValue.typerep;

  -- Yeah, it's a big if/then/else block, but these are all very similar and related.
  top.translation = if q.name == "lexeme" then "new common.StringCatter(lexeme)" else
                    if q.name == "line" then "virtualLocation.getLine()" else
                    if q.name == "column" then "virtualLocation.getColumn()" else
                    if q.name == "filename" then "new common.StringCatter(virtualLocation.getFileName())" else
                    error("unknown actionTerminalReference " ++ q.name); -- should never be called, but here for safety

  top.upSubst = top.downSubst;
  
  forwards to defaultExpr();
}

