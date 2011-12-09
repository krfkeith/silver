grammar silver:driver;

nonterminal IOInterface with io, interfaces, iParser, compiledGrammars;

abstract production compileInterface
top::IOInterface ::= iIn::IO f::String genPath::String{

  local attribute modTime :: IOVal<Integer>;
  modTime = fileTime(genPath ++ f, iIn);

  local attribute i :: IO;
  i = print("\t[" ++ genPath ++ f ++ "]\n", modTime.io);

  local attribute text :: IOVal<String>;
  text = readFile(genPath ++ f, i);

  local attribute ir :: IRootSpec;
  ir = top.iParser(text.iovalue, f).parseTree; -- I'm assuming that interface files never parse error, so we aren't making this pretty.

  local attribute inf :: Interface; 
  inf = fullInterface(modTime.iovalue, f, genPath, ir.spec);

  top.interfaces = [inf];
  top.io = text.io;
}

nonterminal Interface with rSpec, lastModified, interfaceFile, interfaceLocation;

synthesized attribute lastModified :: Integer;
synthesized attribute interfaceFile :: String;
synthesized attribute interfaceLocation :: String;

abstract production rootSpecInterface
top::Interface ::= r::Decorated RootSpec
{
  top.lastModified = 0;
  top.interfaceFile = "_NULL_";
  top.interfaceLocation = "_NULL_";
  top.rSpec = r;
}

abstract production fullInterface
top::Interface ::= i::Integer f::String l::String r::Decorated RootSpec
{
  top.lastModified = i;
  top.interfaceFile = f;
  top.interfaceLocation = l;
  top.rSpec = r;
}






