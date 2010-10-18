grammar silver:analysis:typechecking:core;

attribute upSubst, downSubst, finalSubst occurs on AspectProductionSignature, AspectProductionLHS, AspectRHS, AspectRHSElem, AspectFunctionSignature, AspectFunctionLHS;

aspect production aspectProductionDcl
top::AGDcl ::= 'aspect' 'production' id::QName ns::AspectProductionSignature body::ProductionBody 
{
  local attribute realType :: TypeExp;
  realType = id.lookupValue.typerep;
  
  local attribute aspectType :: TypeExp;
  aspectType = productionTypeExp(ns.outputElement.typerep, getTypesSignature(ns.inputElements));

  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = body.finalSubst;

  errCheck1 = check(realType, aspectType);
  top.errors <-
        if errCheck1.typeerror
        then [err(top.location, "Aspect for '" ++ id.name ++ "' does not have the right signature.\nExpected: "
                                ++ errCheck1.leftpp ++ "\nActual: "
                                ++ errCheck1.rightpp)]
        else [];

  ns.downSubst = emptySubst();
  errCheck1.downSubst = ns.upSubst;
  body.downSubst = errCheck1.upSubst;
  
  body.finalSubst = body.upSubst;
  ns.finalSubst = body.upSubst;
}


aspect production aspectFunctionDcl
top::AGDcl ::= 'aspect' 'function' id::QName ns::AspectFunctionSignature body::ProductionBody 
{
  local attribute realType :: TypeExp;
  realType = id.lookupValue.typerep;
  
  local attribute aspectType :: TypeExp;
  aspectType = functionTypeExp(ns.outputElement.typerep, getTypesSignature(ns.inputElements));

  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = body.finalSubst;

  errCheck1 = check(realType, aspectType);
  top.errors <-
        if errCheck1.typeerror
        then [err(top.location, "Aspect for '" ++ id.name ++ "' does not have the right signature.\nExpected: "
                                ++ errCheck1.leftpp ++ "\nActual: "
                                ++ errCheck1.rightpp)]
        else [];

  ns.downSubst = emptySubst();
  errCheck1.downSubst = ns.upSubst;
  body.downSubst = errCheck1.upSubst;
  
  body.finalSubst = body.upSubst;
  ns.finalSubst = body.upSubst;
}

--

aspect production aspectProductionSignatureEmptyRHS
top::AspectProductionSignature ::= lhs::AspectProductionLHS '::='
{
  lhs.downSubst = top.downSubst;
  top.upSubst = lhs.upSubst;
}

aspect production aspectProductionSignature
top::AspectProductionSignature ::= lhs::AspectProductionLHS '::=' rhs::AspectRHS
{
  lhs.downSubst = top.downSubst;
  rhs.downSubst = lhs.upSubst;
  top.upSubst = rhs.upSubst;
}

aspect production aspectProductionLHSFull
top::AspectProductionLHS ::= id::Name t::TypeExp
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;

  errCheck1.downSubst = top.downSubst;
  top.upSubst = errCheck1.upSubst;
  
  errCheck1 = check(rType, t);
  top.errors <-
        if errCheck1.typeerror
        then [err(top.location, "Type incorrect in aspect signature. Expected: " ++ errCheck1.leftpp ++ "  Got: " ++ errCheck1.rightpp)]
        else [];
}

aspect production aspectRHSElem
top::AspectRHS ::= rhs::AspectRHSElem
{
  rhs.downSubst = top.downSubst;
  top.upSubst = rhs.upSubst;
}

aspect production aspectRHSElemCons
top::AspectRHS ::= h::AspectRHSElem t::AspectRHS
{
  h.downSubst = top.downSubst;
  t.downSubst = h.upSubst;
  top.upSubst = t.upSubst;
}

aspect production aspectRHSElemFull
top::AspectRHSElem ::= id::Name t::TypeExp
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;

  errCheck1.downSubst = top.downSubst;
  top.upSubst = errCheck1.upSubst;
  
  errCheck1 = check(rType, t);
  top.errors <-
        if errCheck1.typeerror
        then [err(top.location, "Type incorrect in aspect signature. Expected: " ++ errCheck1.leftpp ++ "  Got: " ++ errCheck1.rightpp)]
        else [];
}

aspect production aspectFunctionSignatureEmptyRHS
top::AspectFunctionSignature ::= lhs::AspectFunctionLHS '::=' 
{
  lhs.downSubst = top.downSubst;
  top.upSubst = lhs.upSubst;
}

aspect production aspectFunctionSignature
top::AspectFunctionSignature ::= lhs::AspectFunctionLHS '::=' rhs::AspectRHS 
{
  lhs.downSubst = top.downSubst;
  rhs.downSubst = lhs.upSubst;
  top.upSubst = rhs.upSubst;
}

aspect production functionLHSType
top::AspectFunctionLHS ::= t::Type
{
  local attribute errCheck1 :: TypeCheck; errCheck1.finalSubst = top.finalSubst;

  errCheck1.downSubst = top.downSubst;
  top.upSubst = errCheck1.upSubst;
  
  errCheck1 = check(rType, t.typerep);
  top.errors <-
        if errCheck1.typeerror
        then [err(top.location, "Type incorrect in aspect signature. Expected: " ++ errCheck1.leftpp ++ "  Got: " ++ errCheck1.rightpp)]
        else [];
}

