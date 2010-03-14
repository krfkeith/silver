grammar silver:driver;
import silver:util;
import silver:definition:env;

import silver:definition:core;

inherited attribute forceTaint::[String] with ++;
nonterminal DependencyAnalysis with compiledList, needGrammars, interfaces, compiledGrammars, forceTaint;

  -- at this point we need to partition everything into groups:
  -- Group 1: ALTERED.  = extraUnit.compiledList ++ unit.compiledList ++ condUnit.compiledList;
  -- Group 2: TAINTED.  = anything that exports anything ALTERED or TAINTED (inductively)
  -- Group 3: SUSPECT.  = Anything that imports anything ALTERED or TAINTED (noninductively)
  -- Group 4: SAFE.     = All interfaces that aren't in any above group.

abstract production dependencyAnalysis
top::DependencyAnalysis ::= ifaces::[Decorated Interface]
{
  production attribute ifspecs::[Decorated RootSpec];
  ifspecs = getSpecs(ifaces);
  
  production attribute exportsnifs::[[String]];
  exportsnifs = normalizeExports(ifspecs);

  production attribute importsnifs::[[String]];
  importsnifs = normalizeImports(ifspecs);
  
  production attribute altered::[String];
  altered = collectGrammars(top.compiledGrammars); -- actually underwent changes
  
  production attribute taintedaltered::[String]; -- exports something that underwent changes
  taintedaltered = makeSet( top.forceTaint ++ inductivelyExpand(altered, exportsnifs));
  
  production attribute suspect::[String]; -- directly imports something tainted or altered
  suspect = noninductiveExpansion(taintedaltered, importsnifs);
  
  production attribute safe::[String];
  safe = rem(collectGrammars(ifspecs), taintedaltered ++ suspect);

  -- tainted == rem(taintedaltered, altered)
  
  top.compiledList = top.compiledGrammars;
  top.needGrammars = rem(taintedaltered ++ suspect, altered);
  top.interfaces = keepInterfaces(safe, ifaces);
}

function getSpecs
[Decorated RootSpec] ::= s::[Decorated Interface]
{
  return if null(s) then [] else [head(s).rSpec] ++ getSpecs(tail(s));
}

function collectGrammars
[String] ::= lst::[Decorated RootSpec]
{
  return if null(lst) then [] else cons(head(lst).declaredName, collectGrammars(tail(lst)));
}

-- All of these functions give rules of the form [value, conditions.....]
-- put another way, (cadr OR caddr OR cadddr OR ... IMPLIES car)
-- [build what, if what is included]
function normalizeCondBuilds
[[String]] ::= lst::[Decorated RootSpec]
{
  return if null(lst) then [] else head(lst).condBuild ++ normalizeCondBuilds(tail(lst));
}
-- [grammar, grammars exported by this grammar]
function normalizeExports
[[String]] ::= ifs::[Decorated RootSpec]
{
  local attribute n :: String;
  n = head(ifs).declaredName;

  return if null(ifs) then [] else [[n] ++ head(ifs).exportedGrammars] ++ normalizeExports(tail(ifs));
}
-- [grammar, grammars imported by this grammar]
function normalizeImports
[[String]] ::= ifs::[Decorated RootSpec]
{
  local attribute n :: String;
  n = head(ifs).declaredName;

  return if null(ifs) then [] else [[n] ++ head(ifs).moduleNames] ++ normalizeImports(tail(ifs));
}

-- expands initial inductively using rules
function inductivelyExpand
[String] ::= initial::[String] rules::[[String]]
{
  local attribute result::[String];
  result = noninductiveExpansion(initial, rules);
  
  -- We're doing a slight optimization here:
  -- We only have to recursively call with 'result' as the initial set
  -- because the only additions will be those that trigger on one of those
  -- as anything that triggers on anything in 'initial' is in 'result'.
  -- This is thanks to our rules being all disjunctive
  
  return if null(result) then initial else inductivelyExpand(result, rules) ++ initial;
}

-- finds those elements that would be added to initial in "one iteration" of an inductive expansion
function noninductiveExpansion
[String] ::= initial::[String] rules::[[String]]
{
  return if null(rules) then []
         else if containsAny(tail(head(rules)), initial) && !contains(head(head(rules)), initial)
              then head(head(rules)) :: noninductiveExpansion(initial, tail(rules))
              else noninductiveExpansion(initial, tail(rules));
}

function keepInterfaces
[Decorated Interface] ::= k::[String] d::[Decorated Interface]{ 
  return if null(d) then [] else (if contains(head(d).rSpec.declaredName, k) then [head(d)] else []) ++ keepInterfaces(k, tail(d));
}
