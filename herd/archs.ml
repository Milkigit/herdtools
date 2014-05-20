(*********************************************************************)
(*                        Herd                                       *)
(*                                                                   *)
(* Luc Maranget, INRIA Paris-Rocquencourt, France.                   *)
(* Jade Alglave, University College London, UK.                      *)
(*                                                                   *)
(*  Copyright 2013 Institut National de Recherche en Informatique et *)
(*  en Automatique and the authors. All rights reserved.             *)
(*  This file is distributed  under the terms of the Lesser GNU      *)
(*  General Public License.                                          *)
(*********************************************************************)

(*********)
(* Archs *)
(*********)

type t =
  | X86
  | PPC
  | ARM
  | C
  | OpenCL
  | GPU_PTX

let tags = ["X86";"PPC";"ARM";"C";"OpenCL";"GPU_PTX"]

let parse s = match s with
| "X86" -> Some X86
| "PPC" -> Some PPC
| "ARM" -> Some ARM
| "C" -> Some C
| "OpenCL" -> Some OpenCL
| "GPU_PTX" -> Some GPU_PTX
| _ -> None

let lex s = match parse s with
| Some a -> a
| None -> assert false


let pp a = match a with
| X86 -> "X86"
| PPC -> "PPC"
| ARM -> "ARM"
| C -> "C"
| OpenCL -> "OpenCL"
| GPU_PTX -> "GPU_PTX"

let arm = ARM
let ppc = PPC
let x86 = X86
let c = C
let opencl = OpenCL
let gpu_ptx = GPU_PTX
