grammar tutorials:simple:concretesyntax ;

import tutorials:simple:terminals ;
import tutorials:simple:abstractsyntax ;

nonterminal Decl_c, Decls_c with pp, c_code ;

-- Declaration Lists
----------------------------------------
concrete production decl_cons_c
ds::Decls_c ::= d::Decl_c rest::Decls_c
{
 ds.pp = d.pp ++ rest.pp ;
 ds.c_code = d.c_code ++ rest.c_code ;
}

concrete production decl_none_c
ds::Decls_c ::= 
{
 ds.pp = "" ;
 ds.c_code = "" ;
}

-- Declarations
----------------------------------------

-- Function Declaration
concrete production func_decl_c
fd::Decl_c ::= 'func' name::Id_t '('   ')'  
{
 fd.pp = "func " ++ name.lexeme ++ " (  ) \n\n" ;
 fd.c_code = "void " ++ name.lexeme ++ "( ) { \n" ++
             "   printf (\"Hello - in function " ++ 
                          name.lexeme ++ ". \\n\"); \n" ++
             " } \n\n" ;
}
