grammar silver:definition:concrete_syntax;

concrete production concreteProductionDcl
top::AGDcl ::= 'concrete' 'production' id::Name ns::ProductionSignature pm::ProductionModifiers body::ProductionBody
{
  top.pp = "concrete production " ++ id.pp ++ "\n" ++ ns.pp ++ " " ++ pm.pp ++ "\n" ++ body.pp; 
  top.location = $1.location;

  production fName :: String = top.grammarName ++ ":" ++ id.name;
  production namedSig :: NamedSignature = ns.namedSignature;
  
  ns.signatureName = fName;
  ns.env = newScopeEnv(ns.defs, top.env);

  top.errors <- pm.errors;
  top.errors <- ns.concreteSyntaxTypeErrors;

  -- TODO: we should CHANGE syntaxProduction so it just plain takes a NamedSignature!
  top.syntaxAst = [
    syntaxProduction(namedSig,
      foldr(consProductionMod, nilProductionMod(), pm.productionModifiers))];
  
  forwards to productionDcl(terminal(Abstract_kwd, "abstract", $1.location), $2, id, ns, body);
}

nonterminal ProductionModifiers with config, location, file, pp, productionModifiers, errors, env; -- 0 or some
nonterminal ProductionModifierList with config, location, file, pp, productionModifiers, errors, env; -- 1 or more
nonterminal ProductionModifier with config, location, file, pp, productionModifiers, errors, env; -- 1

synthesized attribute productionModifiers :: [SyntaxProductionModifier];

concrete production productionModifiersNone
top::ProductionModifiers ::=
{
  top.pp = "";
  top.location = bogusLocation();

  top.productionModifiers = [];
  top.errors := [];
}
concrete production productionModifierSome
top::ProductionModifiers ::= pm::ProductionModifierList
{
  top.pp = pm.pp;
  top.location = pm.location;
  
  top.productionModifiers = pm.productionModifiers;
  top.errors := pm.errors;
}

concrete production productionModifierSingle
top::ProductionModifierList ::= pm::ProductionModifier
{
  top.pp = pm.pp;
  top.location = pm.location;
  
  top.productionModifiers = pm.productionModifiers;
  top.errors := pm.errors;
}
concrete production productionModifiersCons
top::ProductionModifierList ::= h::ProductionModifier ',' t::ProductionModifierList
{
  top.pp = h.pp ++ ", " ++ t.pp;
  top.location = $2.location;

  top.productionModifiers = h.productionModifiers ++ t.productionModifiers;
  top.errors := h.errors ++ t.errors;
}


concrete production productionModifierPrecedence
top::ProductionModifier ::= 'precedence' '=' i::Int_t
{
  top.pp = "precedence = " ++ i.lexeme;
  top.location = $2.location;

  top.productionModifiers = [prodPrecedence(toInt(i.lexeme))];
  top.errors := [];
}

terminal Operator_kwd /operator/ lexer classes {KEYWORD,RESERVED};

concrete production productionModifierOperator
top::ProductionModifier ::= 'operator' '=' n::QName
{
  top.pp = "operator = " ++ n.pp;
  top.location = $2.location;

  top.productionModifiers = [prodOperator(n.lookupType.fullName)];

  top.errors := n.lookupType.errors ++
                if !n.lookupType.typerep.isTerminal
                then [err(n.location, n.pp ++ " is not a terminal.")]
                else [];
}

--------------------------------------------------------------------------------
-- Type sanity checking on concrete productions

synthesized attribute concreteSyntaxTypeErrors :: [Message] with ++;
attribute concreteSyntaxTypeErrors occurs on ProductionSignature, ProductionRHS, ProductionRHSElem;

aspect production productionSignature
top::ProductionSignature ::= lhs::ProductionLHS '::=' rhs::ProductionRHS 
{
  -- lhs is safe
  top.concreteSyntaxTypeErrors := rhs.concreteSyntaxTypeErrors;
}

aspect production productionRHSNil
top::ProductionRHS ::= 
{
  top.concreteSyntaxTypeErrors := [];
}

aspect production productionRHSCons
top::ProductionRHS ::= h::ProductionRHSElem t::ProductionRHS
{
  top.concreteSyntaxTypeErrors := h.concreteSyntaxTypeErrors ++ t.concreteSyntaxTypeErrors;
}

aspect production productionRHSElem
top::ProductionRHSElem ::= id::Name '::' t::Type
{
  top.concreteSyntaxTypeErrors :=
    if t.typerep.permittedInConcreteSyntax then []
    else [err(t.location, t.pp ++ " is not permitted on concrete productions.  Only terminals and nonterminals (without type variables) can appear here")];
}

synthesized attribute permittedInConcreteSyntax :: Boolean occurs on TypeExp;

aspect default production
top::TypeExp ::=
{
  top.permittedInConcreteSyntax = false;
}

aspect production nonterminalTypeExp
top::TypeExp ::= fn::String params::[TypeExp]
{
  top.permittedInConcreteSyntax = null(params);
}

aspect production terminalTypeExp
top::TypeExp ::= fn::String
{
  top.permittedInConcreteSyntax = true;
}

