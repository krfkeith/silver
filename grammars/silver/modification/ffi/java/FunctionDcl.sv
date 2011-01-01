grammar silver:modification:ffi:java;
import silver:modification:ffi;
import silver:modification:ffi:util;
import silver:translation:java:core;
import silver:translation:java:type;
import silver:definition:core;
import silver:definition:env;
import silver:definition:type;

synthesized attribute ffiTranslationString :: [String] occurs on FFIDef, FFIDefs;

aspect production ffidefsOne
top::FFIDefs ::= one::FFIDef
{
  top.ffiTranslationString = one.ffiTranslationString;
}

aspect production ffidefsMany
top::FFIDefs ::= one::FFIDef more::FFIDefs
{
  top.ffiTranslationString = one.ffiTranslationString ++ more.ffiTranslationString;
}

aspect production ffidef
top::FFIDef ::= name::String_t ':' 'return' code::String_t ';'
{
  top.ffiTranslationString = if name.lexeme == "\"java\"" then [cleanStringLexeme(code.lexeme)] else [];
}

function childAccessor
String ::= t::TypeExp fName::String className::String
{
  return "((" ++ t.transType ++ ")context.childAsIs(" ++ className ++ ".i_" ++ fName  ++ "))";
}

function computeSigTranslation
String ::= str::String sig::Decorated NamedSignature
{
  return percentSubst(str, getNamesSignature(sig.inputElements), mapSignature(childAccessor, sig.inputElements, makeClassName(sig.fullName)));
}


-- TODO: this needs clean up.
-- We should forward either to normal function declaration or special one, rather than IFing EVERYTHING in here!
aspect production functionDclFFI
top::AGDcl ::= 'function' id::Name ns::FunctionSignature body::ProductionBody 'foreign' '{' ffidefs::FFIDefs '}'
{
  top.setupInh := if null(ffidefs.ffiTranslationString)
                  then forward.setupInh
                  else ""; -- hacky hacky!  -- TODO should these be there, or empty?
  top.initProd := if null(ffidefs.ffiTranslationString)
                  then forward.initProd
                  else ""; -- hacky hacky!  -- TODO should these be there, or empty?
  top.initValues := "";
  top.postInit := "";

  local attribute actionResult :: String;
  actionResult = 
     if null(ffidefs.ffiTranslationString)
     then "return (" ++ namedSig.outputElement.typerep.transType ++ ")super.doReturn();\n"
     else "common.DecoratedNode context = this.decorate(); return (" ++ namedSig.outputElement.typerep.transType ++ ")"
          ++ computeSigTranslation(head(ffidefs.ffiTranslationString), namedSig) ++ ";\n";

  top.javaClasses = [["P" ++ id.name,
                      generateFunctionClassString(top.grammarName, id.name, namedSig, actionResult)
                    ]];

  top.errors <- if length(ffidefs.ffiTranslationString) > 1
                then [err(ffidefs.location, "There is more than one Java translation in this FFI function")]
                else [];
}
