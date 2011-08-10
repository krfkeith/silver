grammar simple:extensions:implication;

imports lib:lang;
imports simple:concretesyntax as cst;
imports simple:abstractsyntax;

terminal Implies  '=>'  precedence = 6;

concrete production implies_c
e::cst:Expr ::= l::cst:Expr '=>' r::cst:Expr
{
  e.pp = "(" ++  l.pp ++ " => " ++ r.pp ++ ")";
  e.ast = implies(l.ast, r.ast);
}

abstract production implies
e::Expr ::= l::Expr r::Expr 
{
  e.pp = "(" ++  l.pp ++ " => " ++ r.pp ++ ")";
  --   l => r   is equivalent to   !l || r
  forwards to or(not(l), r);
}
