(*********************************************************************)
(*                          Litmus                                   *)
(*                                                                   *)
(*     Jacques-Pascal Deplaix, INRIA Paris-Rocquencourt, France.     *)
(*     Luc Maranget, INRIA Paris-Rocquencourt, France.               *)
(*                                                                   *)
(*  Copyright 2014 Institut National de Recherche en Informatique et *)
(*  en Automatique and the authors. All rights reserved.             *)
(*  This file is distributed  under the terms of the Lesser GNU      *)
(*  General Public License.                                          *)
(*********************************************************************)

open Printf

let start_comment com proc = sprintf "%cSTART _litmus_P%i" com proc

let end_comment com proc = sprintf "%cEND _litmus_P%i" com proc

let code_fun proc = sprintf "code%i" proc

let dump_code_def chan proc params =
  fprintf chan "__attribute__ ((noinline)) static void %s(%s) {\n"
    (code_fun proc) params

let dump_code_call chan indent proc args =
  fprintf chan "%s%s(%s);\n" indent (code_fun proc) args