grammar silver:modification:copper;

import silver:driver;
import silver:translation:java:driver;

import silver:util:cmdargs;

synthesized attribute forceCopperDump :: Boolean occurs on CmdArgs;

aspect production endCmdArgs
top::CmdArgs ::= _
{
  top.forceCopperDump = false;
}
abstract production copperdumpFlag
top::CmdArgs ::= rest::CmdArgs
{
  top.forceCopperDump = true;
  forwards to rest;
}

aspect production run
top::RunUnit ::= iIn::IO args::[String]
{
  flags <- [pair("--copperdump", flag(copperdumpFlag))];
  flagdescs <- ["\t--copperdump: force copper to dump parse table information\n"];

  postOps <- [generateCS(grammars, depAnalysis.taintedParsers, silvergen)]; 
}

-- InterfaceUtil.sv
synthesized attribute taintedParsers:: [ParserSpec] occurs on DependencyAnalysis;
synthesized attribute allParsers :: [ParserSpec] occurs on DependencyAnalysis;

aspect production dependencyAnalysis
top::DependencyAnalysis ::= ifaces::[Decorated Interface]
{
  top.allParsers = collectParserSpecs(ifspecs ++ top.compiledGrammars); -- collect them from everything
  
  top.taintedParsers = findTaintedParsers(top.allParsers, taintedaltered, altered);
}

function collectParserSpecs
[ParserSpec] ::= rs::[Decorated RootSpec]
{
  return if null(rs) then [] else head(rs).parserSpecs ++ collectParserSpecs(tail(rs));
}

function findTaintedParsers
[ParserSpec] ::= rs::[ParserSpec] ta::[String] a::[String]
{
  return if null(rs) then []
         else if containsAny(ta, head(rs).moduleNames) -- The parser uses an altered/tainted grammar. (TODO: should we include suspect grammars?)
              || startsWithAny(a, head(rs).fullName) -- The parser is IN an altered grammar. (NOT tainted, that's fine.)
              then [head(rs)] ++ findTaintedParsers(tail(rs), ta, a)
              else findTaintedParsers(tail(rs), ta, a);
}



abstract production generateCS
top::Unit ::= grams::[Decorated RootSpec] specs::[ParserSpec] silvergen::String
{
  local attribute pr::IO;
  pr = print("Generating Parsers and Scanners.\n", top.ioIn);
  
  top.io = writeCSSpec(pr, grams, silvergen ++ "src/", specs);
  top.code = 0;
  top.order = 5;
}

function writeCSSpec
IO ::= i::IO grams::[Decorated RootSpec] silvergen::String specs::[ParserSpec]
{
  local attribute p :: ParserSpec;
  p = head(specs);
  p.compiledGrammars = grams;
  
  local attribute ast :: SyntaxRoot;
  ast = p.cstAst; -- TODO: we can check for errors on this parser now!! :D
  
  local attribute parserName :: String;
  parserName = makeParserName(p.fullName);

  local attribute copperFile :: String;
  copperFile = silvergen ++ grammarToPath(hackilyFindGrammarName(p.fullName)) ++ parserName ++ ".copper";

  local attribute printio :: IO;
  printio = print("\t[" ++ p.fullName ++ "]\n", i);
  
  local attribute writeio :: IO;
  writeio = writeFile(copperFile, ast.xmlCopper, printio);
  
  return if null(specs) then i
         else writeCSSpec(writeio, grams, silvergen, tail(specs));
}

aspect production writeBuildFile
top::IOVal<String> ::= i::IO a::Decorated CmdArgs specs::[Decorated RootSpec] silverhome::String silvergen::String da::Decorated DependencyAnalysis
{
  extraTaskdefs <- ["  <taskdef name='copper' classname='edu.umn.cs.melt.copper.ant.CopperAntTask' classpathref='lib.classpath'/>\n" ];
  extraTargets <- ["  <target name='copper'>\n" ++ buildAntParserPart(
                                                                      if a.forceCopperDump then da.allParsers else da.taintedParsers
                                                                      , a) ++ "  </target>\n"];
  extraDepends <- ["copper"];
}

function buildAntParserPart
String ::= r::[ParserSpec] a::Decorated CmdArgs
{
  local attribute p :: ParserSpec;
  p = head(r);

  local attribute parserName :: String;
  parserName = makeParserName(p.fullName);
  
  local attribute hackgn :: String;
  hackgn = hackilyFindGrammarName(p.fullName);
  
  local attribute packagename :: String;
  packagename = makeName(hackgn);
  
  local attribute packagepath :: String;
  packagepath = grammarToPath(hackgn);

  return if null(r) then "" else( 
"    <copper fullClassName='" ++ packagename ++ "." ++ parserName ++ "' inputFile='${src}/" ++ packagepath ++ parserName ++ ".copper' " ++ 
	"outputFile='${src}/" ++ packagepath ++ parserName ++ ".java' skin='xml' warnUselessNTs='no' dump='true' dumpType='html'" ++
	(if a.forceCopperDump then "" else " dumpOnlyOnError='true'") ++ " dumpFile='" ++ parserName ++ ".copperdump.html'"  ++ 
	"/>\n" ++
 	 buildAntParserPart(tail(r), a));
}

-- This exists to infer the path to output copper files to... just from the ParserSpec, without knowing what grammar it is in.
function hackilyFindGrammarName
String ::= svName::String
{
  return substring(0, length(svName) - length(last(explode(":", svName))) - 1, svName);

}
