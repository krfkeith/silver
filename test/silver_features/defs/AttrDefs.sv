
nonterminal Foo;

synthesized attribute foo :: String occurs on Foo;
inherited attribute bar :: String occurs on Foo;

abstract production foo
f1::Foo ::= f2::Foo
{
  -- my syn
  f1.foo = "Hi";
  -- child's inh
  f2.bar = "asdf";
  
  production attribute f3 :: Foo;
  f3 = foo(f1);
  -- local's inh
  f3.bar = "lkjkj";
}

wrongCode "Cannot define inherited attribute on f1" {
  aspect production foo
  f1::Foo ::= f2::Foo
  {
    -- my inh
    f1.bar = "argh";
  }
}

wrongCode "Cannot define synthesized attribute on child f2" {
  aspect production foo
  f1::Foo ::= f2::Foo
  {
    -- child syn
    f2.foo = "what";
  }
}

wrongCode "Cannot define synthesized attribute on local f3" {
  aspect production foo
  f1::Foo ::= f2::Foo
  {
    -- local syn
    f3.foo = "oiwue";
  }
}

terminal ATerminal 'a';

wrongCode "is not a nonterminal" {
  attribute foo occurs on ATerminal;
}

wrongCode "Undeclared type 'a'" {
  synthesized attribute foobad :: Function(a ::= a);
}


