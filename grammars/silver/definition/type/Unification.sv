grammar silver:definition:type;

inherited attribute unifyWith :: TypeExp occurs on TypeExp;
synthesized attribute unify :: Substitution occurs on TypeExp;

--------------------------------------------------------------------------------
aspect production varTypeExp
top::TypeExp ::= tv::TyVar
{
  top.unify = case top.unifyWith of
               varTypeExp(j) -> if tyVarEqual(tv, j)
                                then emptySubst()
                                else subst( tv, top.unifyWith )
             | _ -> if containsTyVar(tv, top.unifyWith.freeVariables)
                    then errorSubst("Infinite type! Tried to unify with " ++ prettyType(top.unifyWith))
                    else subst(tv, top.unifyWith)
              end;
}

aspect production skolemTypeExp
top::TypeExp ::= tv::TyVar
{
  top.unify = case top.unifyWith of
               skolemTypeExp(otv) -> if tyVarEqual(tv, otv)
                                     then emptySubst()
                                     else errorSubst("Tried to unify skolem constant with incompatible skolem constant")
             | _ -> errorSubst("Tried to unify skolem constant with " ++ prettyType(top.unifyWith))
              end;
}

aspect production intTypeExp
top::TypeExp ::=
{
  top.unify = case top.unifyWith of
               intTypeExp() -> emptySubst()
             | _ -> errorSubst("Tried to unify Integer with " ++ prettyType(top.unifyWith))
              end;
}

aspect production boolTypeExp
top::TypeExp ::=
{
  top.unify = case top.unifyWith of
               boolTypeExp() -> emptySubst()
             | _ -> errorSubst("Tried to unify Boolean with " ++ prettyType(top.unifyWith))
              end;
}

aspect production floatTypeExp
top::TypeExp ::=
{
  top.unify = case top.unifyWith of
               floatTypeExp() -> emptySubst()
             | _ -> errorSubst("Tried to unify Float with " ++ prettyType(top.unifyWith))
              end;
}

aspect production stringTypeExp
top::TypeExp ::=
{
  top.unify = case top.unifyWith of
               stringTypeExp() -> emptySubst()
             | _ -> errorSubst("Tried to unify Boolean with " ++ prettyType(top.unifyWith))
              end;
}

aspect production nonterminalTypeExp
top::TypeExp ::= fn::String params::[TypeExp]
{
  top.unify = case top.unifyWith of
               nonterminalTypeExp(ofn, op) -> if fn == ofn
                                            then unifyAll( params, op )
                                            else errorSubst("Tried to unify conflicting nonterminal types " ++ fn ++ " and " ++ ofn)
             | _ -> errorSubst("Tried to unify nonterminal type " ++ fn ++ " with " ++ prettyType(top.unifyWith))
              end;
}

aspect production terminalTypeExp
top::TypeExp ::= fn::String
{
  top.unify = case top.unifyWith of
               terminalTypeExp(ofn) -> if fn == ofn
                                     then emptySubst()
                                     else errorSubst("Tried to unify conflicting terminal types " ++ fn ++ " and " ++ ofn)
             | _ -> errorSubst("Tried to unify terminal type " ++ fn ++ " with " ++ prettyType(top.unifyWith))
              end;
}

aspect production decoratedTypeExp
top::TypeExp ::= te::TypeExp
{
  top.unify = case top.unifyWith of
               decoratedTypeExp(ote) -> unify(te, ote)
             | _ -> errorSubst("Tried to unify decorated type with " ++ prettyType(top.unifyWith))
              end;
}

aspect production functionTypeExp
top::TypeExp ::= out::TypeExp params::[TypeExp]
{
  top.unify = case top.unifyWith of
               functionTypeExp(oo, op) -> unifyAll(new(out) :: params, new(oo) :: op)
             | _ -> errorSubst("Tried to unify function type with " ++ prettyType(top.unifyWith))
              end;
}

aspect production productionTypeExp
top::TypeExp ::= out::TypeExp params::[TypeExp]
{
  top.unify = case top.unifyWith of
               productionTypeExp(oo, op) -> unifyAll(new(out) :: params, new(oo) :: op)
             | _ -> errorSubst("Tried to unify production type with " ++ prettyType(top.unifyWith))
              end;
}

--------------------------------------------------------------------------------

function unify
Substitution ::= te1::TypeExp te2::TypeExp
{
  local attribute leftward :: Substitution;
  leftward = te1.unify;
  te1.unifyWith = te2;
  
  local attribute rightward :: Substitution;
  rightward = te2.unify;
  te2.unifyWith = te1;
  
  return if null(leftward.substErrors)
         then leftward   -- arbitrary choice if both work, but if they are confluent, it's okay
         else rightward; -- arbitrary choice of errors. Non-confluent!!
}

function unifyCheck
Substitution ::= te1::TypeExp te2::TypeExp s::Substitution
{
  return composeSubst( ignoreFailure(s), unify( performSubstitution(te1, s), performSubstitution(te2, s)));
}

function unifyDirectional
Substitution ::= fromte::TypeExp tote::TypeExp
{
  -- Currently, this is built on the assumption that the unification will not fail.
  -- Therefore, for now we will FRAGILEY just call unify 
  -- This is a possible source of bugs/unexpected behavior?
  return unify(fromte, tote);
}

function unifyAll
Substitution ::= te1::[TypeExp] te2::[TypeExp]
{
  local attribute first :: Substitution;
  first = unify(head(te1), head(te2));
  
  return if null(te1) && null(te2)
         then emptySubst()
         else if null(te1) || null(te2)
         then errorSubst("Internal error: unifying mismatching numbers")
         else composeSubst(first, unifyAll( mapSubst(tail(te1), first),
                                            mapSubst(tail(te2), first) ));
}


