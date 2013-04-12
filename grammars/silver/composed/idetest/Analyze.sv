-- This file defines the error demanding function that can be interfaced by IDE plugin written in Java.

--grammar silver:analysis:binding:driver;
grammar silver:composed:idetest;

import silver:driver;
import silver:util:cmdargs;

import silver:definition:core;
import silver:definition:env;

import silver:modification:impide;

-- I just copy and pasted this from BuildProcess for now...
function ideAnalyze
IOVal<[IdeMessage]> ::= args::[String]  svParser::SVParser  sviParser::SVIParser  ioin::IO
{
  local argResult :: ParseResult<Decorated CmdArgs> = parseArgs(args);
  local a :: Decorated CmdArgs = argResult.parseTree;

  -- Let's locally set up and verify the environment
  local envSH :: IOVal<String> = envVar("SILVER_HOME", ioin);
  local envGP :: IOVal<String> = envVar("GRAMMAR_PATH", envSH.io);
  local envSG :: IOVal<String> = envVar("SILVER_GEN", envGP.io);
  
  local silverHome :: String =
    endWithSlash(head(a.silverHomeOption ++ [envSH.iovalue]));
  local silverGen :: String =
    endWithSlash(head(a.genLocation ++ (if envSG.iovalue == "" then [] else [envSG.iovalue]) ++ [silverHome ++ "generated/"]));
  local grammarPath :: [String] =
    map(endWithSlash, a.searchPath ++ [silverHome ++ "grammars/"] ++ explode(":", envGP.iovalue) ++ ["."]);
  local buildGrammar :: String = head(a.buildGrammar);

  local check :: IOVal<[String]> =
    checkEnvironment(a, silverHome, silverGen, grammarPath, buildGrammar, envSG.io);
  
  -- Compile grammars. There's some tricky circular program data flow here:
  local rootStream :: IOVal<[Maybe<RootSpec>]> =
    compileGrammars(svParser, sviParser, grammarPath, silverGen, buildGrammar :: grammarStream, true, check.io);
  
  local unit :: Compilation =
    compilation(
      foldr(consGrammars, nilGrammars(), foldr(consMaybe, [], rootStream.iovalue)),
      foldr(consGrammars, nilGrammars(), foldr(consMaybe, [], reRootStream.iovalue)),
      buildGrammar, silverHome, silverGen);
  unit.config = a;
  
  -- Note that this is used above. This outputs deps, and rootStream informs it.
  local grammarStream :: [String] =
    eatGrammars(1, [buildGrammar], rootStream.iovalue, unit.grammarList);
  
  local reRootStream :: IOVal<[Maybe<RootSpec>]> =
    compileGrammars(svParser, sviParser, grammarPath, silverGen, unit.recheckGrammars, true, rootStream.io);

  --return ioval(rootStream.io, getAllBindingErrors(unit.grammarList));


  local messages :: [IdeMessage] = getAllBindingErrors(unit.grammarList);

  return if !argResult.parseSuccess then ioval(ioin, [makeSysIdeMessage(2, "Parsing failed during build. Resource changed outside IDE? (Need refresh and rebuild).")])
    else if !null(check.iovalue) then ioval(check.io, getSysMessages(check.iovalue))
    else if !head(rootStream.iovalue).isJust then ioval(rootStream.io, [makeSysIdeMessage(2, "The specified grammar (" ++ buildGrammar ++ ") could not be found. Configuration error?")])
    else ioval(rootStream.io, getAllBindingErrors(unit.grammarList));

}

function ideGenerate
IOVal<[IdeMessage]> ::= args::[String]  svParser::SVParser  sviParser::SVIParser  ioin::IO
{
  local argResult :: ParseResult<Decorated CmdArgs> = parseArgs(args);
  local a :: Decorated CmdArgs = argResult.parseTree;

  -- Let's locally set up and verify the environment
  local envSH :: IOVal<String> = envVar("SILVER_HOME", ioin);
  local envGP :: IOVal<String> = envVar("GRAMMAR_PATH", envSH.io);
  local envSG :: IOVal<String> = envVar("SILVER_GEN", envGP.io);
  
  local silverHome :: String =
    endWithSlash(head(a.silverHomeOption ++ [envSH.iovalue]));
  local silverGen :: String =
    endWithSlash(head(a.genLocation ++ (if envSG.iovalue == "" then [] else [envSG.iovalue]) ++ [silverHome ++ "generated/"]));
  local grammarPath :: [String] =
    map(endWithSlash, a.searchPath ++ [silverHome ++ "grammars/"] ++ explode(":", envGP.iovalue) ++ ["."]);
  local buildGrammar :: String = head(a.buildGrammar);

  local check :: IOVal<[String]> =
    checkEnvironment(a, silverHome, silverGen, grammarPath, buildGrammar, envSG.io);
  
  -- Compile grammars. There's some tricky circular program data flow here.
  -- This does an "initial grammar stream" composed of 
  -- grammars and interface files that *locally* seem good.
  local rootStream :: IOVal<[Maybe<RootSpec>]> =
    compileGrammars(svParser, sviParser, grammarPath, silverGen, grammarStream, a.doClean, check.io);

  -- The list of grammars to build. This is circular with the above, producing
  -- a list that's terminated when the response count is equal to the number of emitted
  -- grammar names.
  local grammarStream :: [String] =
    buildGrammar :: eatGrammars(1, [buildGrammar], rootStream.iovalue, unit.grammarList);
  
  -- This is, essentially, a data structure representing a compilation.
  -- Note that it is pure: it doesn't take any actions.
  local unit :: Compilation =
    compilation(
      foldr(consGrammars, nilGrammars(), foldr(consMaybe, [], rootStream.iovalue)),
      foldr(consGrammars, nilGrammars(), foldr(consMaybe, [], reRootStream.iovalue)),
      buildGrammar, silverHome, silverGen);
  unit.config = a;
    
  -- There is a second circularity here where we use unit.recheckGrammars
  -- to supply the second parameter to unit.
  local reRootStream :: IOVal<[Maybe<RootSpec>]> =
    compileGrammars(svParser, sviParser, grammarPath, silverGen, unit.recheckGrammars, true, rootStream.io);

  -- unit.postOps is a "pure value," here's where we make it go.
  local actions :: IOVal<Integer> = runAll(sortUnits(unit.postOps), reRootStream.io);

--  local messages :: [IdeMessage] = getAllBindingErrors(unit.grammarList);

--  local msgStatus :: Pair<Boolean Boolean> = getMsgStatus(messages, pair(false, false));

  return 
{--
    if !argResult.parseSuccess then ioval(ioin, [makeSysIdeMessage(2, "Parsing failed during build. Resource changed outside IDE? (Need refresh and rebuild).")])
    else if !null(check.iovalue) then ioval(check.io, getSysMessages(check.iovalue))
    else if !head(rootStream.iovalue).isJust then ioval(rootStream.io, [makeSysIdeMessage(2, "The specified grammar (" ++ buildGrammar ++ ") could not be found. Configuration error?")])
    else if msgStatus.snd then ioval(ioin, messages)    --errors. abort
    else ioval(actions.io, messages);
--}
         ioval(actions.io, []);
}

-- status is a pair of boolean values indicating if warning (fst) or error (snd) is present
function getMsgStatus
Pair<Boolean Boolean> ::= es::[IdeMessage] status::Pair<Boolean Boolean>
{
  return if null(es)
         then status
         else let 
                  hd :: IdeMessage = head(es)
              in 
                  if hd.severity == 1 then getMsgStatus(tail(es), pair(true, status.snd))         -- warning present
                  else if hd.severity == 2 then getMsgStatus(tail(es), pair(status.fst, true))    -- error present
                  else getMsgStatus(tail(es), status)
              end;
}

function getSysMessages
[IdeMessage] ::= es::[String]
{
  return if null(es)
         then []
         else let 
                  head :: String = head(es)
              in 
                  [makeSysIdeMessage(2, head)] ++ getSysMessages(tail(es))
              end;
}

function getAllBindingErrors
[IdeMessage] ::= specs::[Decorated RootSpec]
{
  return if null(specs)
         then []
         else rewriteMessages(translateToPath(head(specs).declaredName), head(specs).errors) ++ getAllBindingErrors(tail(specs));
}

function rewriteMessages
[IdeMessage] ::= path::String es::[Message]
{
  return if null(es)
         then []
         else let 
                  head :: Message = head(es)
              in 
                  [makeIdeMessage(path, head.loc, head.severity, head.msg)] ++ rewriteMessages(path, tail(es))
              end;
}

function translateToPath
String ::= declaredName::String
{
  return implode("/", explode(":", declaredName));
}

