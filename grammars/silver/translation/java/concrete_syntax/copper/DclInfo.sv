grammar silver:translation:java:concrete_syntax:copper;

-- These do not need to go into defaultDcl, because they appear on lexer class only
-- which have their own namespace.  We're essentially defining these to be the required
-- attributes of anything that appears in this namespace.
attribute submitsTo,termDominates occurs on DclInfo;

aspect production defaultDcl
top::DclInfo ::=
{
}

abstract production parserAttrDcl
top::DclInfo ::= sg::String sl::Decorated Location fn::String ty::TypeExp
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  ty.boundVariables = top.boundVariables; -- explicit to make sure it errors if we can't
  top.unparse = "parse_attr(" ++ sl.unparse ++ ", '" ++ fn ++ "', " ++ ty.unparse ++ ")";
  
  top.typerep = ty;
  
  top.refDispatcher = parserAttributeReference;
  top.defDispatcher = parserAttributeValueDef;
  top.defLHSDispatcher = parserAttributeDefLHS;

  forwards to defaultDcl();
}

abstract production pluckTermDcl
top::DclInfo ::= sg::String sl::Decorated Location fn::String
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  top.unparse = error("Internal error: pluck-terms should never appear in interface files.");
  
  top.typerep = errorType(); -- TODO: need a real type for this
  
  top.refDispatcher = pluckTerminalReference;
  top.defDispatcher = errorValueDef;
  top.defLHSDispatcher = errorDefLHS;

  forwards to defaultDcl();
}

abstract production disambigLexemeDcl
top::DclInfo ::= sg::String sl::Decorated Location
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = "lexeme";

  top.unparse = error("Internal error: disambig-lexeme should never appear in interface files.");
  
  top.typerep = stringTypeExp();
  
  top.refDispatcher = disambigLexemeReference;
  top.defDispatcher = errorValueDef;
  top.defLHSDispatcher = errorDefLHS;

  forwards to defaultDcl();
}

abstract production lexerClassDcl
top::DclInfo ::= sg::String sl::Decorated Location fn::String tst::[String] td::[String]
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  top.unparse = "lexer_class(" ++ sl.unparse ++ ", '" ++ fn ++ "', [" ++ implode(", ", quoteStrings(tst)) ++ "], [" ++ implode(", ", quoteStrings(td)) ++ "])";
  
  top.submitsTo = tst;
  top.termDominates = td;
  
  forwards to defaultDcl();
}

abstract production termAttrValueDcl
top::DclInfo ::= sg::String sl::Decorated Location fn::String ty::TypeExp
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  top.unparse = error("INTERNAL ERROR: terminal attribute values should never appear in interface files");
  
  top.typerep = ty;
  
  top.refDispatcher = termAttrValueReference;
  top.defDispatcher = termAttrValueValueDef;
  top.defLHSDispatcher = errorDefLHS;

  forwards to defaultDcl();
}

abstract production actionChildDcl
top::DclInfo ::= sg::String sl::Decorated Location fn::String ty::TypeExp
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  top.unparse = error("INTERNAL ERROR: action block child values should never appear in interface files");
  
  top.typerep = ty;
  
  top.refDispatcher = actionChildReference;
  top.defDispatcher = errorValueDef;
  top.defLHSDispatcher = parserAttributeDefLHS; -- TODO: specialize this

  forwards to defaultDcl();
}

abstract production parserLocalDcl
top::DclInfo ::= sg::String sl::Decorated Location fn::String ty::TypeExp
{
  top.sourceGrammar = sg;
  top.sourceLocation = sl;
  top.fullName = fn;

  top.unparse = error("INTERNAL ERROR: local parser attributes should never appear in interface files");
  
  top.typerep = ty;
  
  -- TODO: use specialized ones that give better errors messages!
  top.refDispatcher = parserAttributeReference;
  top.defDispatcher = parserAttributeValueDef;
  top.defLHSDispatcher = parserAttributeDefLHS;

  forwards to defaultDcl();
}

