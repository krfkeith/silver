grammar silver:definition:flow:env;

import silver:definition:type:syntax;
import silver:modification:defaultattr;
import silver:modification:collection;
import silver:modification:copper;
import silver:util only contains;
import silver:driver only computeOptionalDeps;

attribute flowDefs, flowEnv occurs on ProductionBody, ProductionStmts, ProductionStmt, ForwardInhs, ForwardInh;

{- A short note on how flowDefs are generated:

  - We ALWAYS produce the flowDef itself. This is necessary to catch missing or duplicate equations.
  - We omit the dependencies if it appears in a location not permitted to affect the flow type.
    This is to allow us to just compute flow types once, globally.
-}

aspect production defaultProductionBody
top::ProductionBody ::= stmts::ProductionStmts
{
  top.flowDefs = stmts.flowDefs;
}

----

aspect production productionStmtsNone
top::ProductionStmts ::= 
{
  top.flowDefs = [];
}

aspect production productionStmts
top::ProductionStmts ::= stmt::ProductionStmt
{
  top.flowDefs = stmt.flowDefs;
}

aspect production productionStmtsCons
top::ProductionStmts ::= h::ProductionStmt  t::ProductionStmts
{
  top.flowDefs = h.flowDefs ++ t.flowDefs;
}

aspect production productionStmtsAppend
top::ProductionStmts ::= h::ProductionStmts  t::ProductionStmts
{
  top.flowDefs = h.flowDefs ++ t.flowDefs;
}

----

aspect production productionStmtAppend
top::ProductionStmt ::= h::ProductionStmt  t::ProductionStmt
{
  top.flowDefs = h.flowDefs ++ t.flowDefs;
}

{-
aspect default production
top::ProductionStmt ::=
{
  top.flowDefs = [];
}
-}

----

aspect production forwardsTo
top::ProductionStmt ::= 'forwards' 'to' e::Expr ';'
{
  local ntDefGram :: String = hackGramFromFName(top.signature.outputElement.typerep.typeName);

  local mayAffectFlowType :: Boolean =
    contains(top.grammarName, computeOptionalDeps([ntDefGram], top.compiledGrammars));
  
  top.flowDefs = [fwdEq(top.signature.fullName, e.flowDeps, mayAffectFlowType)];
}
aspect production forwardsToWith
top::ProductionStmt ::= 'forwards' 'to' e::Expr 'with' '{' inh::ForwardInhs '}' ';'
{
  local ntDefGram :: String = hackGramFromFName(top.signature.outputElement.typerep.typeName);

  local mayAffectFlowType :: Boolean =
    contains(top.grammarName, computeOptionalDeps([ntDefGram], top.compiledGrammars));
  
  top.flowDefs = [fwdEq(top.signature.fullName, e.flowDeps, mayAffectFlowType)] ++ inh.flowDefs;
}
aspect production forwardingWith
top::ProductionStmt ::= 'forwarding' 'with' '{' inh::ForwardInhs '}' ';'
{
  top.flowDefs = inh.flowDefs;
}

aspect production forwardInhsOne
top::ForwardInhs ::= lhs::ForwardInh
{
  top.flowDefs = lhs.flowDefs;
}
aspect production forwardInhsCons
top::ForwardInhs ::= lhs::ForwardInh rhs::ForwardInhs
{
  top.flowDefs = lhs.flowDefs ++ rhs.flowDefs;
}
aspect production forwardInh
top::ForwardInh ::= lhs::ForwardLHSExpr '=' e::Expr ';'
{
  -- TODO figure out if we need to omit deps for inhs??
  top.flowDefs =
    case lhs of
    | forwardLhsExpr(q) -> [fwdInhEq(top.signature.fullName, q.lookupAttribute.fullName, e.flowDeps)]
    end;
}

aspect production localAttributeDcl
top::ProductionStmt ::= 'local' 'attribute' a::Name '::' te::Type ';'
{
  top.flowDefs = [];
}
aspect production returnDef
top::ProductionStmt ::= 'return' e::Expr ';'
{
  top.flowDefs = [];
}
aspect production errorAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' e::Expr
{
  top.flowDefs = [];
}

aspect production synthesizedAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' e::Expr
{
  local ntDefGram :: String = hackGramFromFName(top.signature.outputElement.typerep.typeName);

  local mayAffectFlowType :: Boolean =
    contains(top.grammarName, computeOptionalDeps([ntDefGram, occursCheck.dcl.sourceGrammar], top.compiledGrammars));
  
  top.flowDefs = 
    case top.blockContext of -- TODO: this may not be the bestest way to go about doing this....
    | defaultAspectContext() -> [defEq(top.signature.outputElement.typerep.typeName, attr.lookupAttribute.fullName, e.flowDeps)]
    | _ -> [synEq(top.signature.fullName, attr.lookupAttribute.fullName, e.flowDeps, mayAffectFlowType)]
    end;
}
aspect production inheritedAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' e::Expr
{
  -- TODO: figure out if we need to omit deps for inhs??
  top.flowDefs = 
    case dl of
    | childDefLHS(q) -> [inhEq(top.signature.fullName, q.lookupValue.fullName, attr.lookupAttribute.fullName, e.flowDeps)]
    | localDefLHS(q) -> [localInhEq(top.signature.fullName, q.lookupValue.fullName, attr.lookupAttribute.fullName, e.flowDeps)]
    | forwardDefLHS(q) -> [fwdInhEq(top.signature.fullName, attr.lookupAttribute.fullName, e.flowDeps)]
    | _ -> [] -- TODO : this isn't quite extensible... more better way eventually, plz
    end;
}

aspect production localValueDef
top::ProductionStmt ::= val::Decorated QName '=' e::Expr
{
  -- TODO: So, I'm just going to assume for the moment that we're always allowed to define the eq for a local...
  -- technically, it's possible to break this if you declare it in one grammar, but define it in another, but
  -- I think we should forbid that syntactically, later on...
  top.flowDefs = [localEq(top.signature.fullName, val.lookupValue.fullName, val.lookupValue.typerep.typeName, e.flowDeps)];
}
aspect production errorValueDef
top::ProductionStmt ::= val::Decorated QName '=' e::Expr
{
  top.flowDefs = [];
}

-- FROM COLLECTIONS TODO

aspect production synAppendColAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' {-That's really a <- -} e::Expr
{
  local ntDefGram :: String = hackGramFromFName(top.signature.outputElement.typerep.typeName);

  local mayAffectFlowType :: Boolean =
    contains(top.grammarName, computeOptionalDeps([ntDefGram], top.compiledGrammars));

  top.flowDefs = [extraEq(top.signature.fullName, lhsVertex(attr.lookupAttribute.fullName), e.flowDeps, mayAffectFlowType)];
}

aspect production inhAppendColAttributeDef
top::ProductionStmt ::= dl::DefLHS '.' attr::Decorated QName '=' e::Expr
{
  -- TODO: figure out if we need to omit deps for inhs??
  local vertex :: FlowVertex =
    case dl of
    | childDefLHS(q) -> rhsVertex(q.lookupValue.fullName, attr.lookupAttribute.fullName)
    | localDefLHS(q) -> localVertex(q.lookupValue.fullName, attr.lookupAttribute.fullName)
    | forwardDefLHS(q) -> forwardVertex(attr.lookupAttribute.fullName)
    | _ -> localEqVertex("bogus:value:from:inhcontrib:flow")
    end;
  top.flowDefs = [extraEq(top.signature.fullName, vertex, e.flowDeps, true)];
}

------ FROM COPPER TODO

aspect production pluckDef
top::ProductionStmt ::= 'pluck' e::Expr ';'
{
  top.flowDefs = [];
}

aspect production printStmt
top::ProductionStmt ::= 'print' e::Expr ';'
{
  top.flowDefs = [];
}

aspect production parserAttributeValueDef
top::ProductionStmt ::= val::Decorated QName '=' e::Expr
{
  top.flowDefs = [];
}

aspect production termAttrValueValueDef
top::ProductionStmt ::= val::Decorated QName '=' e::Expr
{
  top.flowDefs = [];
}


-- FROM DEFAULTATTR TODO
{-
aspect production defaultLhsDefLHS
top::DefLHS ::= q::Decorated QName
{
  top.partialVertex = lhsVertex;
}
-}



--- A few helper functions

function hackGramFromFName
String ::= s::String
{
  return substring(0, lastIndexOf(":", s), s);
}


