%{
open Constant
open CPP11Base
%}

%token EOF
%token LK
%token <CPP11Base.reg> ARCH_REG
%token <int> NUM
%token <string> NAME
%token <string> ATOMIC_NAME
%token <int> PROC
%token SEMI COMMA PIPE COLON LPAR RPAR EQ DOT LBRACE RBRACE STAR
%token WHILE IF ELSE 
%token VOLATILE UNSIGNED SIGNED ATOMIC LONG DOUBLE BOOL
%token <CPP11Base.mem_order> MEMORDER
%token <CPP11Base.location_kind> LOCATIONKIND

/* Instruction tokens */

%token LD ST FENCE LOCK UNLOCK SCAS WCAS

%type <LocationKindMap.lk_map> lk_map
%type <(int * CPP11Base.pseudo list) list * MiscParser.gpu_data option> main 
%start  main

%%

main: 
| procs lk_map EOF 
  { Printf.printf "Hello";
      let gpu = { MiscParser.empty_gpu with MiscParser.lk_map=$2 } in
     ($1,Some gpu) }

procs:
|   { [] }
| PROC LPAR params RPAR LBRACE instr_list RBRACE procs
    { ($1, $6) :: $8 } /* TODO: Ignores params */

instr_list:
|            { [] }
| instr instr_list 
             { $1 :: $2 }

instr:
| basic_instr SEMI     
             { Instruction $1} 
| WHILE LPAR basic_instr RPAR LBRACE instr_list RBRACE 
             { Loop ($3,$6) }
| IF LPAR basic_instr RPAR LBRACE instr_list RBRACE ELSE LBRACE instr_list RBRACE
             { Choice ($3,$6,$10) }

basic_instr:
  | reg EQ loc DOT LD LPAR MEMORDER RPAR
    {Pload ($3,$1,$7)}
  | loc DOT ST LPAR store_op COMMA MEMORDER RPAR
    {Pstore ($1,$5,$7)}
  | loc EQ store_op
    {Pstore ($1,$3,NA)}
  | reg EQ loc
    {Pload ($3,$1,NA)}
  | FENCE LPAR MEMORDER RPAR
    {Pfence ($3)}
  | LOCK LPAR loc RPAR
    {Plock ($3)}
  | UNLOCK LPAR loc RPAR
    {Punlock ($3)}
  | WCAS LPAR loc COMMA loc COMMA store_op COMMA MEMORDER COMMA MEMORDER RPAR
    {Pcas ($3,$5,$7,$9,$11,false)}
  | SCAS LPAR loc COMMA loc COMMA store_op COMMA MEMORDER COMMA MEMORDER RPAR
    {Pcas ($3,$5,$7,$9,$11,true)}

store_op :
| NUM { Concrete $1 }

reg:
| ARCH_REG { $1 }

loc:
| NAME { Symbolic $1 }


params:
| { [] }
/*
| ty NAME
    { [{CAst.param_ty = $1; volatile = false; param_name = $2}] }
| VOLATILE ty NAME
    { [{CAst.param_ty = $2; volatile = true; param_name = $3}] }
| ty NAME COMMA params
    { {CAst.param_ty = $1; volatile = false; param_name = $2} :: $4 }
| VOLATILE ty NAME COMMA params
    { {CAst.param_ty = $2; volatile = true; param_name = $3} :: $5 }

ty:
| atyp STAR { RunType.Ty $1 }
| atyp STAR STAR { RunType.Pointer $1 }

atyp:
| typ { $1 }
| ATOMIC typ { "_Atomic " ^ $2 }

typ:
| ATOMIC_NAME { $1 }
| ty_attr NAME { $1 ^ $2 }
| ty_attr LONG { $1 ^ "long" }
| ty_attr DOUBLE { $1 ^ "double" }
| ty_attr LONG LONG { $1 ^ "long long" }
| ty_attr LONG DOUBLE { $1 ^ "long double" }
| BOOL { "_Bool" }

ty_attr:
| { "" }
| UNSIGNED { "unsigned " }
| SIGNED { "signed " }
*/

lk_map:
| LK lk_list { $2 }
|         { [] }

lk_list:
| lk { [$1] }
| lk COMMA lk_list { $1 :: $3 }

lk:
| NAME COLON LOCATIONKIND { ($1,$3) }

