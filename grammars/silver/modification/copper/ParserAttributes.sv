grammar silver:modification:copper;

concrete production attributeDclParser
top::AGDcl ::= 'parser' 'attribute' a::Name '::' te::Type 'action' acode::ActionCode_c ';'
{
  top.pp = "parser attribute " ++ a.name ++ " :: " ++ te.pp ++ " action " ++ acode.pp ++ " ;" ;

  production attribute fName :: String;
  fName = top.grammarName ++ ":" ++ a.name;

  top.defs = [parserAttrDef(top.grammarName, a.location, fName, te.typerep)];

  top.errors <- if length(getValueDclAll(fName, top.env)) > 1
                then [err(a.location, "Attribute '" ++ fName ++ "' is already bound.")]
                else [];

  top.errors := te.errors ++ acode.errors;
  
  acode.signature = namedNamedSignature(fName);
  acode.blockContext = actionContext();
  acode.env = newScopeEnv(acode.defs, top.env);
  
  top.syntaxAst = [syntaxParserAttribute(fName, te.typerep, acode.actionCode)];
}

