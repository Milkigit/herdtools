%{
open Constant
open CPP11Base
open CType
%}

%token EOF
%token LK
%token <CPP11Base.reg> ARCH_REG
%token <int> CONSTANT
%token <string> IDENTIFIER
%token <string> ATOMIC_TYPE
%token <int> PROC
%token SEMI COMMA PIPE COLON LPAR RPAR EQ EQ_OP DOT LBRACE RBRACE STAR
%token WHILE IF ELSE

%nonassoc LOWER_THAN_ELSE /* This fixes the dangling-else problem */
%nonassoc ELSE
 
%token UNSIGNED SIGNED ATOMIC LONG DOUBLE BOOL INT VOID FLOAT CHAR SHORT
%token MUTEX 
%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CONST VOLATILE 
%token <CPP11Base.mem_order> MEMORDER

/* Instruction tokens */

%token LD LD_EXPLICIT ST ST_EXPLICIT FENCE LOCK UNLOCK SCAS WCAS

%type <(int * CPP11Base.pseudo list) list * MiscParser.gpu_data option> main 
%type <(CPP11Base.pseudo list) CAst.test list> translation_unit
%start main

%%

main: 
| translation_unit EOF 
  { let proc_list,param_map = 
      List.fold_right (fun p (proc_list, param_map) -> 
        let proc_list = (p.CAst.proc,p.CAst.body) :: proc_list in
        let param_map = p.CAst.params :: param_map in
        (proc_list, param_map)) $1 ([], [])  
    in
    let additional = 
      { MiscParser.empty_gpu with 
        MiscParser.param_map = param_map; } 
    in
    (proc_list, Some additional) }

primary_expression:
| ARCH_REG 
  { Eregister $1 }
| CONSTANT 
  { Econstant (Concrete $1) }
| loc
  { Econstant $1 }
| LPAR expression RPAR 
  { Eparen $2 }

postfix_expression:
| primary_expression 
  { $1 }
| ST LPAR addr COMMA assignment_expression RPAR
  { Estore ($3, $5, CPP11Base.SC) }
| ST_EXPLICIT LPAR addr COMMA assignment_expression COMMA MEMORDER RPAR
  { Estore ($3, $5, $7) }
| LD LPAR addr RPAR
  { Eload ($3, CPP11Base.SC) }
| LD_EXPLICIT LPAR addr COMMA MEMORDER RPAR
  { Eload ($3, $5) }
| FENCE LPAR MEMORDER RPAR
  { Efence ($3) }
| LOCK LPAR loc RPAR
  { Elock ($3) }
| UNLOCK LPAR loc RPAR
  { Eunlock ($3) }
| WCAS LPAR loc COMMA loc COMMA assignment_expression COMMA MEMORDER COMMA MEMORDER RPAR
  { Ecas ($3,$5,$7,$9,$11,false) }
| SCAS LPAR loc COMMA loc COMMA assignment_expression COMMA MEMORDER COMMA MEMORDER RPAR
  { Ecas ($3,$5,$7,$9,$11,true) }

unary_expression:
| postfix_expression 
  { $1 }
| STAR addr
  { Eload ($2, CPP11Base.NA) }

cast_expression:
| unary_expression { $1 }

multiplicative_expression:
| cast_expression { $1 }

additive_expression:
| multiplicative_expression { $1 }

shift_expression:
| additive_expression { $1 }

relational_expression:
| shift_expression { $1 }

equality_expression:
| relational_expression 
  { $1 }
| equality_expression EQ_OP relational_expression 
  { Eeq ($1,$3) }

and_expression:
| equality_expression { $1 }

exclusive_or_expression:
| and_expression { $1 }

inclusive_or_expression: 
| exclusive_or_expression { $1 }

logical_and_expression: 
| inclusive_or_expression { $1 }

logical_or_expression:
| logical_and_expression { $1 }

conditional_expression:
| logical_or_expression { $1 }

assignment_expression:
| conditional_expression 
  { $1 }
| ARCH_REG assignment_operator assignment_expression
  { Eassign ($1, $3) }
| STAR addr assignment_operator assignment_expression
  { Estore ($2, $4, CPP11Base.NA) }

assignment_operator:
| EQ { () }

expression:
| assignment_expression { $1 }
| expression COMMA assignment_expression { Ecomma ($1,$3) }

declaration:
| typ  init_declarator SEMI  { $2; }

init_declarator:
| ARCH_REG
  { Pblock [] }
| ARCH_REG EQ initialiser 
  { Pexpr (Eassign ($1, $3)) }

parameter_type_list:
| parameter_list { $1 }

parameter_list:
| parameter_declaration
  { [$1] }
| parameter_list COMMA parameter_declaration
  { $1 @ [$3] }

parameter_declaration:
| typstar IDENTIFIER
  { {CAst.param_ty = $1; param_name = $2} }

initialiser:
| assignment_expression 
  { $1 }

statement:
| declaration /* (* Added to allow mid-block declarations *) */
  { $1 }
| compound_statement
  { Pblock $1 }
| expression_statement
  { $1 }
| selection_statement
  { $1 }
| iteration_statement
  { $1 }

compound_statement:
| LBRACE RBRACE
  { [] }
| LBRACE statement_list RBRACE
  { $2 }

statement_list:
| statement
  { [$1] }
| statement statement_list
  { $1 :: $2 }

expression_statement:
| SEMI
  { Pblock [] }
| expression SEMI
  { Pexpr $1 }

selection_statement:
| IF LPAR expression RPAR statement %prec LOWER_THAN_ELSE
  { Pif ($3, $5, Pblock []) }
| IF LPAR expression RPAR statement ELSE statement
  { Pif ($3, $5, $7) }

iteration_statement:
| WHILE LPAR expression RPAR statement
  { Pwhile($3,$5) }

translation_unit:
| external_declaration
  { [$1] }
| translation_unit external_declaration 
  { $1 @ [$2] }

external_declaration:
| function_definition { $1 }

function_definition:
| PROC LPAR parameter_type_list RPAR compound_statement
  { { CAst.proc = $1; 
      CAst.params = $3; 
      CAst.body = List.map (fun ins -> Instruction ins) $5 } }

loc:
| IDENTIFIER { Symbolic $1 }

addr:
| loc { AddrDirect $1 }
| ARCH_REG { AddrIndirect $1 }

typstar:
| typ STAR { Pointer $1 }

typ:
| typ STAR { Pointer $1 } 
| typ VOLATILE { Volatile $1 } 
| ATOMIC base { Atomic $2 }
| VOLATILE base0 { Volatile $2 }
| base { $1 }

base0:
| ATOMIC_TYPE { Atomic (Base $1) }
| ty_attr MUTEX { Base ($1 ^ "mutex") }
| ty_attr CHAR { Base ($1 ^ "char") }
| ty_attr INT { Base ($1 ^ "int") }
| ty_attr LONG { Base ($1 ^ "long") }
| ty_attr FLOAT { Base ($1 ^ "float") }
| ty_attr DOUBLE { Base ($1 ^ "double") }
| ty_attr LONG LONG { Base ($1 ^ "long long") }
| ty_attr LONG DOUBLE { Base ($1 ^ "long double") }
| BOOL { Base ("_Bool") }

base:
| base0 { $1 }
| LPAR typ RPAR { $2 }

ty_attr:
| { "" }
| UNSIGNED { "unsigned " }
| SIGNED { "signed " }
