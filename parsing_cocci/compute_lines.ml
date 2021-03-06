(*
 * Copyright 2010, INRIA, University of Copenhagen
 * Julia Lawall, Rene Rydhof Hansen, Gilles Muller, Nicolas Palix
 * Copyright 2005-2009, Ecole des Mines de Nantes, University of Copenhagen
 * Yoann Padioleau, Julia Lawall, Rene Rydhof Hansen, Henrik Stuart, Gilles Muller, Nicolas Palix
 * This file is part of Coccinelle.
 *
 * Coccinelle is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, according to version 2 of the License.
 *
 * Coccinelle is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Coccinelle.  If not, see <http://www.gnu.org/licenses/>.
 *
 * The authors reserve the right to distribute this or future versions of
 * Coccinelle under other licenses.
 *)


(* Computes starting and ending logical lines for statements and
expressions.  every node gets an index as well. *)

module Ast0 = Ast0_cocci
module Ast = Ast_cocci

(* --------------------------------------------------------------------- *)
(* Result *)

(* This is a horrible hack.  We need to have a special treatment for the code
inside a nest, and this is to avoid threading that information around
everywhere *)
let in_nest_count = ref 0
let check_attachable v = if !in_nest_count > 0 then false else v

let mkres x e left right =
  let lstart = Ast0.get_info left in
  let lend = Ast0.get_info right in
  let pos_info =
    { Ast0.line_start = lstart.Ast0.pos_info.Ast0.line_start;
      Ast0.line_end = lend.Ast0.pos_info.Ast0.line_end;
      Ast0.logical_start = lstart.Ast0.pos_info.Ast0.logical_start;
      Ast0.logical_end = lend.Ast0.pos_info.Ast0.logical_end;
      Ast0.column = lstart.Ast0.pos_info.Ast0.column;
      Ast0.offset = lstart.Ast0.pos_info.Ast0.offset;} in
  let info =
    { Ast0.pos_info = pos_info;
      Ast0.attachable_start = check_attachable lstart.Ast0.attachable_start;
      Ast0.attachable_end = check_attachable lend.Ast0.attachable_end;
      Ast0.mcode_start = lstart.Ast0.mcode_start;
      Ast0.mcode_end = lend.Ast0.mcode_end;
      (* only for tokens, not inherited upwards *)
      Ast0.strings_before = []; Ast0.strings_after = [] } in
  {x with Ast0.node = e; Ast0.info = info}

(* This looks like it is there to allow distribution of plus code
over disjunctions.  But this doesn't work with single_statement, as the
plus code has not been distributed to the place that it expects.  So the
only reasonably easy solution seems to be to disallow distribution. *)
(* inherit attachable is because single_statement doesn't work well when +
code is attached outside an or, but this has to be allowed after
isomorphisms have been introduced.  So only set it to true then, or when we
know that the code involved cannot contain a statement, ie it is a
declaration. *)
let inherit_attachable = ref false
let mkmultires x e left right (astart,start_mcodes) (aend,end_mcodes) =
  let lstart = Ast0.get_info left in
  let lend = Ast0.get_info right in
  let pos_info =
    { Ast0.line_start = lstart.Ast0.pos_info.Ast0.line_start;
      Ast0.line_end = lend.Ast0.pos_info.Ast0.line_end;
      Ast0.logical_start = lstart.Ast0.pos_info.Ast0.logical_start;
      Ast0.logical_end = lend.Ast0.pos_info.Ast0.logical_end;
      Ast0.column = lstart.Ast0.pos_info.Ast0.column;
      Ast0.offset = lstart.Ast0.pos_info.Ast0.offset; } in
  let info =
    { Ast0.pos_info = pos_info;
      Ast0.attachable_start =
      check_attachable (if !inherit_attachable then astart else false);
      Ast0.attachable_end =
      check_attachable (if !inherit_attachable then aend else false);
      Ast0.mcode_start = start_mcodes;
      Ast0.mcode_end = end_mcodes;
      (* only for tokens, not inherited upwards *)
      Ast0.strings_before = []; Ast0.strings_after = [] } in
  {x with Ast0.node = e; Ast0.info = info}

(* --------------------------------------------------------------------- *)

let get_option fn = function
    None -> None
  | Some x -> Some (fn x)

(* --------------------------------------------------------------------- *)
(* --------------------------------------------------------------------- *)
(* Mcode *)

let promote_mcode (_,_,info,mcodekind,_,_) =
  let new_info =
    {info with
      Ast0.mcode_start = [mcodekind]; Ast0.mcode_end = [mcodekind]} in
  {(Ast0.wrap ()) with Ast0.info = new_info; Ast0.mcodekind = ref mcodekind}

let promote_mcode_plus_one (_,_,info,mcodekind,_,_) =
  let new_pos_info =
    {info.Ast0.pos_info with
      Ast0.line_start = info.Ast0.pos_info.Ast0.line_start + 1;
      Ast0.logical_start = info.Ast0.pos_info.Ast0.logical_start + 1;
      Ast0.line_end = info.Ast0.pos_info.Ast0.line_end + 1;
      Ast0.logical_end = info.Ast0.pos_info.Ast0.logical_end + 1; } in
  let new_info =
    {info with
      Ast0.pos_info = new_pos_info;
      Ast0.mcode_start = [mcodekind]; Ast0.mcode_end = [mcodekind]} in
  {(Ast0.wrap ()) with Ast0.info = new_info; Ast0.mcodekind = ref mcodekind}

let promote_to_statement stm mcodekind =
  let info = Ast0.get_info stm in
  let new_pos_info =
    {info.Ast0.pos_info with
      Ast0.logical_start = info.Ast0.pos_info.Ast0.logical_end;
      Ast0.line_start = info.Ast0.pos_info.Ast0.line_end; } in
  let new_info =
    {info with
      Ast0.pos_info = new_pos_info;
      Ast0.mcode_start = [mcodekind]; Ast0.mcode_end = [mcodekind];
      Ast0.attachable_start = check_attachable true;
      Ast0.attachable_end = check_attachable true} in
  {(Ast0.wrap ()) with Ast0.info = new_info; Ast0.mcodekind = ref mcodekind}

let promote_to_statement_start stm mcodekind =
  let info = Ast0.get_info stm in
  let new_pos_info =
    {info.Ast0.pos_info with
      Ast0.logical_end = info.Ast0.pos_info.Ast0.logical_start;
      Ast0.line_end = info.Ast0.pos_info.Ast0.line_start; } in
  let new_info =
    {info with
      Ast0.pos_info = new_pos_info;
      Ast0.mcode_start = [mcodekind]; Ast0.mcode_end = [mcodekind];
      Ast0.attachable_start = check_attachable true;
      Ast0.attachable_end = check_attachable true} in
  {(Ast0.wrap ()) with Ast0.info = new_info; Ast0.mcodekind = ref mcodekind}

(* mcode is good by default *)
let bad_mcode (t,a,info,mcodekind,pos,adj) =
  let new_info =
    {info with
      Ast0.attachable_start = check_attachable false;
      Ast0.attachable_end = check_attachable false} in
  (t,a,new_info,mcodekind,pos,adj)

let get_all_start_info l =
  (List.for_all (function x -> (Ast0.get_info x).Ast0.attachable_start) l,
   List.concat (List.map (function x -> (Ast0.get_info x).Ast0.mcode_start) l))

let get_all_end_info l =
  (List.for_all (function x -> (Ast0.get_info x).Ast0.attachable_end) l,
   List.concat (List.map (function x -> (Ast0.get_info x).Ast0.mcode_end) l))

(* --------------------------------------------------------------------- *)
(* Dots *)

(* for the logline classification and the mcode field, on both sides, skip
over initial minus dots, as they don't contribute anything *)
let dot_list is_dots fn = function
    [] -> failwith "dots should not be empty"
  | l ->
      let get_node l fn =
	let first = List.hd l in
	let chosen =
	  match (is_dots first, l) with (true,_::x::_) -> x | _ -> first in
	(* get the logline decorator and the mcodekind of the chosen node *)
	fn (Ast0.get_info chosen) in
      let forward = List.map fn l in
      let backward = List.rev forward in
      let (first_attachable,first_mcode) =
	get_node forward
	  (function x -> (x.Ast0.attachable_start,x.Ast0.mcode_start)) in
      let (last_attachable,last_mcode) =
	get_node backward
	  (function x -> (x.Ast0.attachable_end,x.Ast0.mcode_end)) in
      let first = List.hd forward in
      let last = List.hd backward in
      let first_info =
	{ (Ast0.get_info first) with
	  Ast0.attachable_start = check_attachable first_attachable;
	  Ast0.mcode_start = first_mcode } in
      let last_info =
	{ (Ast0.get_info last) with
	  Ast0.attachable_end = check_attachable last_attachable;
	  Ast0.mcode_end = last_mcode } in
      let first = Ast0.set_info first first_info in
      let last = Ast0.set_info last last_info in
      (forward,first,last)

let dots is_dots prev fn d =
  match (prev,Ast0.unwrap d) with
    (Some prev,Ast0.DOTS([])) ->
      mkres d (Ast0.DOTS []) prev prev
  | (None,Ast0.DOTS([])) ->
      Ast0.set_info d
	{(Ast0.get_info d)
	with
	  Ast0.attachable_start = check_attachable false;
	  Ast0.attachable_end = check_attachable false}
  | (_,Ast0.DOTS(x)) ->
      let (l,lstart,lend) = dot_list is_dots fn x in
      mkres d (Ast0.DOTS l) lstart lend
  | (_,Ast0.CIRCLES(x)) ->
      let (l,lstart,lend) = dot_list is_dots fn x in
      mkres d (Ast0.CIRCLES l) lstart lend
  | (_,Ast0.STARS(x)) ->
      let (l,lstart,lend) = dot_list is_dots fn x in
      mkres d (Ast0.STARS l) lstart lend

(* --------------------------------------------------------------------- *)
(* Disjunctions *)

let do_disj e starter xs mids ender processor rebuilder =
  let starter = bad_mcode starter in
  let xs = List.map processor xs in
  let mids = List.map bad_mcode mids in
  let ender = bad_mcode ender in
  mkmultires e (rebuilder starter xs mids ender)
    (promote_mcode starter) (promote_mcode ender)
    (get_all_start_info xs) (get_all_end_info xs)

(* --------------------------------------------------------------------- *)
(* Identifier *)

(* for #define name, with no value, to compute right side *)
let mkidres a b c d r = (mkres a b c d,r)

let rec full_ident i =
  match Ast0.unwrap i with
    Ast0.Id(name) as ui ->
      let name = promote_mcode name in mkidres i ui name name (Some name)
  | Ast0.MetaId(name,_,_)
  | Ast0.MetaFunc(name,_,_) | Ast0.MetaLocalFunc(name,_,_) as ui ->
      let name = promote_mcode name in mkidres i ui name name (Some name)
  | Ast0.DisjId(starter,ids,mids,ender) ->
      let res =
	do_disj i starter ids mids ender ident
	  (fun starter ids mids ender ->
	    Ast0.DisjId(starter,ids,mids,ender)) in
      (res,None)
  | Ast0.OptIdent(id) ->
      let (id,r) = full_ident id in mkidres i (Ast0.OptIdent(id)) id id r
  | Ast0.UniqueIdent(id) ->
      let (id,r) = full_ident id in mkidres i (Ast0.UniqueIdent(id)) id id r
and ident i = let (id,_) = full_ident i in id

(* --------------------------------------------------------------------- *)
(* Expression *)

let is_exp_dots e =
  match Ast0.unwrap e with
    Ast0.Edots(_,_) | Ast0.Ecircles(_,_) | Ast0.Estars(_,_) -> true
  | _ -> false

let rec expression e =
  match Ast0.unwrap e with
    Ast0.Ident(id) ->
      let id = ident id in
      mkres e (Ast0.Ident(id)) id id
  | Ast0.Constant(const) as ue ->
      let ln = promote_mcode const in
      mkres e ue ln ln
  | Ast0.FunCall(fn,lp,args,rp) ->
      let fn = expression fn in
      let args = dots is_exp_dots (Some(promote_mcode lp)) expression args in
      mkres e (Ast0.FunCall(fn,lp,args,rp)) fn (promote_mcode rp)
  | Ast0.Assignment(left,op,right,simple) ->
      let left = expression left in
      let right = expression right in
      mkres e (Ast0.Assignment(left,op,right,simple)) left right
  | Ast0.CondExpr(exp1,why,exp2,colon,exp3) ->
      let exp1 = expression exp1 in
      let exp2 = get_option expression exp2 in
      let exp3 = expression exp3 in
      mkres e (Ast0.CondExpr(exp1,why,exp2,colon,exp3)) exp1 exp3
  | Ast0.Postfix(exp,op) ->
      let exp = expression exp in
      mkres e (Ast0.Postfix(exp,op)) exp (promote_mcode op)
  | Ast0.Infix(exp,op) ->
      let exp = expression exp in
      mkres e (Ast0.Infix(exp,op)) (promote_mcode op) exp
  | Ast0.Unary(exp,op) ->
      let exp = expression exp in
      mkres e (Ast0.Unary(exp,op)) (promote_mcode op) exp
  | Ast0.Binary(left,op,right) ->
      let left = expression left in
      let right = expression right in
      mkres e (Ast0.Binary(left,op,right)) left right
  | Ast0.Nested(left,op,right) ->
      let left = expression left in
      let right = expression right in
      mkres e (Ast0.Nested(left,op,right)) left right
  | Ast0.Paren(lp,exp,rp) ->
      mkres e (Ast0.Paren(lp,expression exp,rp))
	(promote_mcode lp) (promote_mcode rp)
  | Ast0.ArrayAccess(exp1,lb,exp2,rb) ->
      let exp1 = expression exp1 in
      let exp2 = expression exp2 in
      mkres e (Ast0.ArrayAccess(exp1,lb,exp2,rb)) exp1 (promote_mcode rb)
  | Ast0.RecordAccess(exp,pt,field) ->
      let exp = expression exp in
      let field = ident field in
      mkres e (Ast0.RecordAccess(exp,pt,field)) exp field
  | Ast0.RecordPtAccess(exp,ar,field) ->
      let exp = expression exp in
      let field = ident field in
      mkres e (Ast0.RecordPtAccess(exp,ar,field)) exp field
  | Ast0.Cast(lp,ty,rp,exp) ->
      let exp = expression exp in
      mkres e (Ast0.Cast(lp,typeC ty,rp,exp)) (promote_mcode lp) exp
  | Ast0.SizeOfExpr(szf,exp) ->
      let exp = expression exp in
      mkres e (Ast0.SizeOfExpr(szf,exp)) (promote_mcode szf) exp
  | Ast0.SizeOfType(szf,lp,ty,rp) ->
      mkres e (Ast0.SizeOfType(szf,lp,typeC ty,rp))
        (promote_mcode szf)  (promote_mcode rp)
  | Ast0.TypeExp(ty) ->
      let ty = typeC ty in mkres e (Ast0.TypeExp(ty)) ty ty
  | Ast0.MetaErr(name,_,_) | Ast0.MetaExpr(name,_,_,_,_)
  | Ast0.MetaExprList(name,_,_) as ue ->
      let ln = promote_mcode name in mkres e ue ln ln
  | Ast0.EComma(cm) ->
      (*let cm = bad_mcode cm in*) (* why was this bad??? *)
      let ln = promote_mcode cm in
      mkres e (Ast0.EComma(cm)) ln ln
  | Ast0.DisjExpr(starter,exps,mids,ender) ->
      do_disj e starter exps mids ender expression
	(fun starter exps mids ender -> Ast0.DisjExpr(starter,exps,mids,ender))
  | Ast0.NestExpr(starter,exp_dots,ender,whencode,multi) ->
      let exp_dots = dots is_exp_dots None expression exp_dots in
      let starter = bad_mcode starter in
      let ender = bad_mcode ender in
      mkres e (Ast0.NestExpr(starter,exp_dots,ender,whencode,multi))
	(promote_mcode starter) (promote_mcode ender)
  | Ast0.Edots(dots,whencode) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres e (Ast0.Edots(dots,whencode)) ln ln
  | Ast0.Ecircles(dots,whencode) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres e (Ast0.Ecircles(dots,whencode)) ln ln
  | Ast0.Estars(dots,whencode) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres e (Ast0.Estars(dots,whencode)) ln ln
  | Ast0.OptExp(exp) ->
      let exp = expression exp in
      mkres e (Ast0.OptExp(exp)) exp exp
  | Ast0.UniqueExp(exp) ->
      let exp = expression exp in
      mkres e (Ast0.UniqueExp(exp)) exp exp

and expression_dots x = dots is_exp_dots None expression x

(* --------------------------------------------------------------------- *)
(* Types *)

and typeC t =
  match Ast0.unwrap t with
    Ast0.ConstVol(cv,ty) ->
      let ty = typeC ty in
      mkres t (Ast0.ConstVol(cv,ty)) (promote_mcode cv) ty
  | Ast0.BaseType(ty,strings) as ut ->
      let first = List.hd strings in
      let last = List.hd (List.rev strings) in
      mkres t ut (promote_mcode first) (promote_mcode last)
  | Ast0.Signed(sgn,None) as ut ->
      mkres t ut (promote_mcode sgn) (promote_mcode sgn)
  | Ast0.Signed(sgn,Some ty) ->
      let ty = typeC ty in
      mkres t (Ast0.Signed(sgn,Some ty)) (promote_mcode sgn) ty
  | Ast0.Pointer(ty,star) ->
      let ty = typeC ty in
      mkres t (Ast0.Pointer(ty,star)) ty (promote_mcode star)
  | Ast0.FunctionPointer(ty,lp1,star,rp1,lp2,params,rp2) ->
      let ty = typeC ty in
      let params = parameter_list (Some(promote_mcode lp2)) params in
      mkres t (Ast0.FunctionPointer(ty,lp1,star,rp1,lp2,params,rp2))
	ty (promote_mcode rp2)
  | Ast0.FunctionType(Some ty,lp1,params,rp1) ->
      let ty = typeC ty in
      let params = parameter_list (Some(promote_mcode lp1)) params in
      let res = Ast0.FunctionType(Some ty,lp1,params,rp1) in
      mkres t res ty (promote_mcode rp1)
  | Ast0.FunctionType(None,lp1,params,rp1) ->
      let params = parameter_list (Some(promote_mcode lp1)) params in
      let res = Ast0.FunctionType(None,lp1,params,rp1) in
      mkres t res (promote_mcode lp1) (promote_mcode rp1)
  | Ast0.Array(ty,lb,size,rb) ->
      let ty = typeC ty in
      mkres t (Ast0.Array(ty,lb,get_option expression size,rb))
	ty (promote_mcode rb)
  | Ast0.EnumName(kind,Some name) ->
      let name = ident name in
      mkres t (Ast0.EnumName(kind,Some name)) (promote_mcode kind) name
  | Ast0.EnumName(kind,None) ->
      let mc = promote_mcode kind in
      mkres t (Ast0.EnumName(kind,None)) mc mc
  | Ast0.EnumDef(ty,lb,ids,rb) ->
      let ty = typeC ty in
      let ids = dots is_exp_dots (Some(promote_mcode lb)) expression ids in
      mkres t (Ast0.EnumDef(ty,lb,ids,rb)) ty (promote_mcode rb)
  | Ast0.StructUnionName(kind,Some name) ->
      let name = ident name in
      mkres t (Ast0.StructUnionName(kind,Some name)) (promote_mcode kind) name
  | Ast0.StructUnionName(kind,None) ->
      let mc = promote_mcode kind in
      mkres t (Ast0.StructUnionName(kind,None)) mc mc
  | Ast0.StructUnionDef(ty,lb,decls,rb) ->
      let ty = typeC ty in
      let decls =
	dots is_decl_dots (Some(promote_mcode lb)) declaration decls in
      mkres t (Ast0.StructUnionDef(ty,lb,decls,rb)) ty (promote_mcode rb)
  | Ast0.TypeName(name) as ut ->
      let ln = promote_mcode name in mkres t ut ln ln
  | Ast0.MetaType(name,_) as ut ->
      let ln = promote_mcode name in mkres t ut ln ln
  | Ast0.DisjType(starter,types,mids,ender) ->
      do_disj t starter types mids ender typeC
	(fun starter types mids ender ->
	  Ast0.DisjType(starter,types,mids,ender))
  | Ast0.OptType(ty) ->
      let ty = typeC ty in mkres t (Ast0.OptType(ty)) ty ty
  | Ast0.UniqueType(ty) ->
      let ty = typeC ty in mkres t (Ast0.UniqueType(ty)) ty ty

(* --------------------------------------------------------------------- *)
(* Variable declaration *)
(* Even if the Cocci program specifies a list of declarations, they are
   split out into multiple declarations of a single variable each. *)

and is_decl_dots s =
  match Ast0.unwrap s with
    Ast0.Ddots(_,_) -> true
  | _ -> false

and declaration d =
  match Ast0.unwrap d with
    (Ast0.MetaDecl(name,_) | Ast0.MetaField(name,_)) as up ->
      let ln = promote_mcode name in mkres d up ln ln
  | Ast0.Init(stg,ty,id,eq,exp,sem) ->
      let ty = typeC ty in
      let id = ident id in
      let exp = initialiser exp in
      (match stg with
	None ->
	  mkres d (Ast0.Init(stg,ty,id,eq,exp,sem)) ty (promote_mcode sem)
      | Some x ->
	  mkres d (Ast0.Init(stg,ty,id,eq,exp,sem))
	    (promote_mcode x) (promote_mcode sem))
  | Ast0.UnInit(stg,ty,id,sem) ->
      let ty = typeC ty in
      let id = ident id in
      (match stg with
	None ->
	  mkres d (Ast0.UnInit(stg,ty,id,sem)) ty (promote_mcode sem)
      | Some x ->
	  mkres d (Ast0.UnInit(stg,ty,id,sem))
	    (promote_mcode x) (promote_mcode sem))
  | Ast0.MacroDecl(name,lp,args,rp,sem) ->
      let name = ident name in
      let args = dots is_exp_dots (Some(promote_mcode lp)) expression args in
      mkres d (Ast0.MacroDecl(name,lp,args,rp,sem)) name (promote_mcode sem)
  | Ast0.TyDecl(ty,sem) ->
      let ty = typeC ty in
      mkres d (Ast0.TyDecl(ty,sem)) ty (promote_mcode sem)
  | Ast0.Typedef(stg,ty,id,sem) ->
      let ty = typeC ty in
      let id = typeC id in
      mkres d (Ast0.Typedef(stg,ty,id,sem))
	(promote_mcode stg) (promote_mcode sem)
  | Ast0.DisjDecl(starter,decls,mids,ender) ->
      do_disj d starter decls mids ender declaration
	(fun starter decls mids ender ->
	  Ast0.DisjDecl(starter,decls,mids,ender))
  | Ast0.Ddots(dots,whencode) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres d (Ast0.Ddots(dots,whencode)) ln ln
  | Ast0.OptDecl(decl) ->
      let decl = declaration decl in
      mkres d (Ast0.OptDecl(declaration decl)) decl decl
  | Ast0.UniqueDecl(decl) ->
      let decl = declaration decl in
      mkres d (Ast0.UniqueDecl(declaration decl)) decl decl

(* --------------------------------------------------------------------- *)
(* Initializer *)

and is_init_dots i =
  match Ast0.unwrap i with
    Ast0.Idots(_,_) -> true
  | _ -> false

and initialiser i =
  match Ast0.unwrap i with
    Ast0.MetaInit(name,_) as ut ->
      let ln = promote_mcode name in mkres i ut ln ln
  | Ast0.InitExpr(exp) ->
      let exp = expression exp in
      mkres i (Ast0.InitExpr(exp)) exp exp
  | Ast0.InitList(lb,initlist,rb,ordered) ->
      let initlist =
	dots is_init_dots (Some(promote_mcode lb)) initialiser initlist in
      mkres i (Ast0.InitList(lb,initlist,rb,ordered))
	(promote_mcode lb) (promote_mcode rb)
  | Ast0.InitGccExt(designators,eq,ini) ->
      let (delims,designators) = (* non empty due to parsing *)
	List.split (List.map designator designators) in
      let ini = initialiser ini in
      mkres i (Ast0.InitGccExt(designators,eq,ini))
	(promote_mcode (List.hd delims)) ini
  | Ast0.InitGccName(name,eq,ini) ->
      let name = ident name in
      let ini = initialiser ini in
      mkres i (Ast0.InitGccName(name,eq,ini)) name ini
  | Ast0.IComma(cm) as up ->
      let ln = promote_mcode cm in mkres i up ln ln
  | Ast0.Idots(dots,whencode) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres i (Ast0.Idots(dots,whencode)) ln ln
  | Ast0.OptIni(ini) ->
      let ini = initialiser ini in
      mkres i (Ast0.OptIni(ini)) ini ini
  | Ast0.UniqueIni(ini) ->
      let ini = initialiser ini in
      mkres i (Ast0.UniqueIni(ini)) ini ini

and designator = function
    Ast0.DesignatorField(dot,id) ->
      (dot,Ast0.DesignatorField(dot,ident id))
  | Ast0.DesignatorIndex(lb,exp,rb) ->
      (lb,Ast0.DesignatorIndex(lb,expression exp,rb))
  | Ast0.DesignatorRange(lb,min,dots,max,rb) ->
      (lb,Ast0.DesignatorRange(lb,expression min,dots,expression max,rb))

and initialiser_list prev = dots is_init_dots prev initialiser

(* for export *)
and initialiser_dots x = dots is_init_dots None initialiser x

(* --------------------------------------------------------------------- *)
(* Parameter *)

and is_param_dots p =
  match Ast0.unwrap p with
    Ast0.Pdots(_) | Ast0.Pcircles(_) -> true
  | _ -> false

and parameterTypeDef p =
  match Ast0.unwrap p with
    Ast0.VoidParam(ty) ->
      let ty = typeC ty in mkres p (Ast0.VoidParam(ty)) ty ty
  | Ast0.Param(ty,Some id) ->
      let id = ident id in
      let ty = typeC ty in mkres p (Ast0.Param(ty,Some id)) ty id
  | Ast0.Param(ty,None) ->
      let ty = typeC ty in mkres p (Ast0.Param(ty,None)) ty ty
  | Ast0.MetaParam(name,_) as up ->
      let ln = promote_mcode name in mkres p up ln ln
  | Ast0.MetaParamList(name,_,_) as up ->
      let ln = promote_mcode name in mkres p up ln ln
  | Ast0.PComma(cm) ->
      (*let cm = bad_mcode cm in*) (* why was this bad??? *)
      let ln = promote_mcode cm in
      mkres p (Ast0.PComma(cm)) ln ln
  | Ast0.Pdots(dots) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres p (Ast0.Pdots(dots)) ln ln
  | Ast0.Pcircles(dots) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres p (Ast0.Pcircles(dots)) ln ln
  | Ast0.OptParam(param) ->
      let res = parameterTypeDef param in
      mkres p (Ast0.OptParam(res)) res res
  | Ast0.UniqueParam(param) ->
      let res = parameterTypeDef param in
      mkres p (Ast0.UniqueParam(res)) res res

and parameter_list prev = dots is_param_dots prev parameterTypeDef

(* for export *)
let parameter_dots x = dots is_param_dots None parameterTypeDef x

(* --------------------------------------------------------------------- *)

let is_define_param_dots s =
  match Ast0.unwrap s with
    Ast0.DPdots(_) | Ast0.DPcircles(_) -> true
  | _ -> false

let rec define_param p =
  match Ast0.unwrap p with
    Ast0.DParam(id) ->
      let id = ident id in mkres p (Ast0.DParam(id)) id id
  | Ast0.DPComma(cm) ->
      (*let cm = bad_mcode cm in*) (* why was this bad??? *)
      let ln = promote_mcode cm in
      mkres p (Ast0.DPComma(cm)) ln ln
  | Ast0.DPdots(dots) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres p (Ast0.DPdots(dots)) ln ln
  | Ast0.DPcircles(dots) ->
      let dots = bad_mcode dots in
      let ln = promote_mcode dots in
      mkres p (Ast0.DPcircles(dots)) ln ln
  | Ast0.OptDParam(dp) ->
      let res = define_param dp in
      mkres p (Ast0.OptDParam(res)) res res
  | Ast0.UniqueDParam(dp) ->
      let res = define_param dp in
      mkres p (Ast0.UniqueDParam(res)) res res

let define_parameters x id =
  match Ast0.unwrap x with
    Ast0.NoParams -> (x,id) (* no info, should be ignored *)
  | Ast0.DParams(lp,dp,rp) ->
      let dp = dots is_define_param_dots None define_param dp in
      let l = promote_mcode lp in
      let r = promote_mcode rp in
      (mkres x (Ast0.DParams(lp,dp,rp)) l r, r)

(* --------------------------------------------------------------------- *)
(* Top-level code *)

let is_stm_dots s =
  match Ast0.unwrap s with
    Ast0.Dots(_,_) | Ast0.Circles(_,_) | Ast0.Stars(_,_) -> true
  | _ -> false

let rec statement s =
  let res =
    match Ast0.unwrap s with
      Ast0.Decl((_,bef),decl) ->
	let decl = declaration decl in
	let left = promote_to_statement_start decl bef in
	mkres s (Ast0.Decl((Ast0.get_info left,bef),decl)) decl decl
    | Ast0.Seq(lbrace,body,rbrace) ->
	let body =
	  dots is_stm_dots (Some(promote_mcode lbrace)) statement body in
	mkres s (Ast0.Seq(lbrace,body,rbrace))
	  (promote_mcode lbrace) (promote_mcode rbrace)
    | Ast0.ExprStatement(exp,sem) ->
	let exp = expression exp in
	mkres s (Ast0.ExprStatement(exp,sem)) exp (promote_mcode sem)
    | Ast0.IfThen(iff,lp,exp,rp,branch,(_,aft)) ->
	let exp = expression exp in
	let branch = statement branch in
	let right = promote_to_statement branch aft in
	mkres s (Ast0.IfThen(iff,lp,exp,rp,branch,(Ast0.get_info right,aft)))
	  (promote_mcode iff) right
    | Ast0.IfThenElse(iff,lp,exp,rp,branch1,els,branch2,(_,aft)) ->
	let exp = expression exp in
	let branch1 = statement branch1 in
	let branch2 = statement branch2 in
	let right = promote_to_statement branch2 aft in
	mkres s
	  (Ast0.IfThenElse(iff,lp,exp,rp,branch1,els,branch2,
	    (Ast0.get_info right,aft)))
	  (promote_mcode iff) right
    | Ast0.While(wh,lp,exp,rp,body,(_,aft)) ->
	let exp = expression exp in
	let body = statement body in
	let right = promote_to_statement body aft in
	mkres s (Ast0.While(wh,lp,exp,rp,body,(Ast0.get_info right,aft)))
	  (promote_mcode wh) right
    | Ast0.Do(d,body,wh,lp,exp,rp,sem) ->
	let body = statement body in
	let exp = expression exp in
	mkres s (Ast0.Do(d,body,wh,lp,exp,rp,sem))
	  (promote_mcode d) (promote_mcode sem)
    | Ast0.For(fr,lp,exp1,sem1,exp2,sem2,exp3,rp,body,(_,aft)) ->
	let exp1 = get_option expression exp1 in
	let exp2 = get_option expression exp2 in
	let exp3 = get_option expression exp3 in
	let body = statement body in
	let right = promote_to_statement body aft in
	mkres s (Ast0.For(fr,lp,exp1,sem1,exp2,sem2,exp3,rp,body,
			  (Ast0.get_info right,aft)))
	  (promote_mcode fr) right
    | Ast0.Iterator(nm,lp,args,rp,body,(_,aft)) ->
	let nm = ident nm in
	let args = dots is_exp_dots (Some(promote_mcode lp)) expression args in
	let body = statement body in
	let right = promote_to_statement body aft in
	mkres s (Ast0.Iterator(nm,lp,args,rp,body,(Ast0.get_info right,aft)))
	  nm right
    | Ast0.Switch(switch,lp,exp,rp,lb,decls,cases,rb) ->
	let exp = expression exp in
	let decls =
	  dots is_stm_dots (Some(promote_mcode lb))
	    statement decls in
	let cases =
	  dots (function _ -> false)
	    (if Ast0.undots decls = []
	    then (Some(promote_mcode lb))
	    else None (* not sure this is right, but not sure the case can
			 arise either *))
	    case_line cases in
	mkres s
	  (Ast0.Switch(switch,lp,exp,rp,lb,decls,cases,rb))
	  (promote_mcode switch) (promote_mcode rb)
    | Ast0.Break(br,sem) as us ->
	mkres s us (promote_mcode br) (promote_mcode sem)
    | Ast0.Continue(cont,sem) as us ->
	mkres s us (promote_mcode cont) (promote_mcode sem)
    | Ast0.Label(l,dd) ->
	let l = ident l in
	mkres s (Ast0.Label(l,dd)) l (promote_mcode dd)
    | Ast0.Goto(goto,id,sem) ->
	let id = ident id in
	mkres s (Ast0.Goto(goto,id,sem))
	  (promote_mcode goto) (promote_mcode sem)
    | Ast0.Return(ret,sem) as us ->
	mkres s us (promote_mcode ret) (promote_mcode sem)
    | Ast0.ReturnExpr(ret,exp,sem) ->
	let exp = expression exp in
	mkres s (Ast0.ReturnExpr(ret,exp,sem))
	  (promote_mcode ret) (promote_mcode sem)
    | Ast0.MetaStmt(name,_)
    | Ast0.MetaStmtList(name,_) as us ->
	let ln = promote_mcode name in mkres s us ln ln
    | Ast0.Exp(exp) ->
	let exp = expression exp in
	mkres s (Ast0.Exp(exp)) exp exp
    | Ast0.TopExp(exp) ->
	let exp = expression exp in
	mkres s (Ast0.TopExp(exp)) exp exp
    | Ast0.Ty(ty) ->
	let ty = typeC ty in
	mkres s (Ast0.Ty(ty)) ty ty
    | Ast0.TopInit(init) ->
	let init = initialiser init in
	mkres s (Ast0.TopInit(init)) init init
    | Ast0.Disj(starter,rule_elem_dots_list,mids,ender) ->
	let starter = bad_mcode starter in
	let mids = List.map bad_mcode mids in
	let ender = bad_mcode ender in
	let rec loop prevs = function
	    [] -> []
	  | stm::stms ->
	      (dots is_stm_dots (Some(promote_mcode_plus_one(List.hd prevs)))
		 statement stm)::
	      (loop (List.tl prevs) stms) in
	let elems = loop (starter::mids) rule_elem_dots_list in
	mkmultires s (Ast0.Disj(starter,elems,mids,ender))
	  (promote_mcode starter) (promote_mcode ender)
	  (get_all_start_info elems) (get_all_end_info elems)
    | Ast0.Nest(starter,rule_elem_dots,ender,whencode,multi) ->
	let starter = bad_mcode starter in
	let ender = bad_mcode ender in
	let wrapper f =
	  match Ast0.get_mcode_mcodekind starter with
	    Ast0.MINUS _ ->
	      (* if minus, then all nest code has to be minus.  This is
		 checked at the token level, in parse_cocci.ml.  All nest code
		 is also unattachable.  We strip the minus annotations from
		 the nest code because in the CTL another metavariable will
		 take care of removing all the code matched by the nest.
		 Without stripping the minus annotations, we would get a
		 double transformation.  Perhaps there is a more elegant
		 way to do this in the CTL, but it is not easy, because of
		 the interaction with the whencode and the implementation of
		 plus *)
	      in_nest_count := !in_nest_count + 1;
	      let res = f() in
	      in_nest_count := !in_nest_count - 1;
	      res
	  | _ -> f() in
	let rule_elem_dots =
	  wrapper
	    (function _ -> dots is_stm_dots None statement rule_elem_dots) in
	mkres s (Ast0.Nest(starter,rule_elem_dots,ender,whencode,multi))
	  (promote_mcode starter) (promote_mcode ender)
    | Ast0.Dots(dots,whencode) ->
	let dots = bad_mcode dots in
	let ln = promote_mcode dots in
	mkres s (Ast0.Dots(dots,whencode)) ln ln
    | Ast0.Circles(dots,whencode) ->
	let dots = bad_mcode dots in
	let ln = promote_mcode dots in
	mkres s (Ast0.Circles(dots,whencode)) ln ln
    | Ast0.Stars(dots,whencode) ->
	let dots = bad_mcode dots in
	let ln = promote_mcode dots in
	mkres s (Ast0.Stars(dots,whencode)) ln ln
    | Ast0.FunDecl((_,bef),fninfo,name,lp,params,rp,lbrace,body,rbrace) ->
	let fninfo =
	  List.map
	    (function Ast0.FType(ty) -> Ast0.FType(typeC ty) | x -> x)
	    fninfo in
	let name = ident name in
	let params = parameter_list (Some(promote_mcode lp)) params in
	let body =
	  dots is_stm_dots (Some(promote_mcode lbrace)) statement body in
	let left =
	(* cases on what is leftmost *)
	  match fninfo with
	    [] -> promote_to_statement_start name bef
	  | Ast0.FStorage(stg)::_ ->
	      promote_to_statement_start (promote_mcode stg) bef
	  | Ast0.FType(ty)::_ ->
	      promote_to_statement_start ty bef
	  | Ast0.FInline(inline)::_ ->
	      promote_to_statement_start (promote_mcode inline) bef
	  | Ast0.FAttr(attr)::_ ->
	      promote_to_statement_start (promote_mcode attr) bef in
      (* pretend it is one line before the start of the function, so that it
	 will catch things defined at top level.  We assume that these will not
	 be defined on the same line as the function.  This is a HACK.
	 A better approach would be to attach top_level things to this node,
	 and other things to the node after, but that would complicate
	 insert_plus, which doesn't distinguish between different mcodekinds *)
	let res =
	  Ast0.FunDecl((Ast0.get_info left,bef),fninfo,name,lp,params,rp,lbrace,
		       body,rbrace) in
      (* have to do this test again, because of typing problems - can't save
	 the result, only use it *)
	(match fninfo with
	  [] -> mkres s res name (promote_mcode rbrace)
	| Ast0.FStorage(stg)::_ ->
	    mkres s res (promote_mcode stg) (promote_mcode rbrace)
	| Ast0.FType(ty)::_ -> mkres s res ty (promote_mcode rbrace)
	| Ast0.FInline(inline)::_ ->
	    mkres s res (promote_mcode inline) (promote_mcode rbrace)
	| Ast0.FAttr(attr)::_ ->
	    mkres s res (promote_mcode attr) (promote_mcode rbrace))

    | Ast0.Include(inc,stm) ->
	mkres s (Ast0.Include(inc,stm)) (promote_mcode inc) (promote_mcode stm)
    | Ast0.Undef(def,id) ->
	let id = ident id in
	mkres s (Ast0.Undef(def,id)) (promote_mcode def) id
    | Ast0.Define(def,id,params,body) ->
	let (id,right) = full_ident id in
	(match right with
	  None -> failwith "no disj id for #define"
	| Some right ->
	    let (params,prev) = define_parameters params right in
	    let body = dots is_stm_dots (Some prev) statement body in
	    mkres s (Ast0.Define(def,id,params,body)) (promote_mcode def) body)
    | Ast0.OptStm(stm) ->
	let stm = statement stm in mkres s (Ast0.OptStm(stm)) stm stm
    | Ast0.UniqueStm(stm) ->
	let stm = statement stm in mkres s (Ast0.UniqueStm(stm)) stm stm in
  Ast0.set_dots_bef_aft res
    (match Ast0.get_dots_bef_aft res with
      Ast0.NoDots -> Ast0.NoDots
    | Ast0.AddingBetweenDots s ->
	Ast0.AddingBetweenDots(statement s)
    | Ast0.DroppingBetweenDots s ->
	Ast0.DroppingBetweenDots(statement s))

and case_line c =
  match Ast0.unwrap c with
    Ast0.Default(def,colon,code) ->
      let code = dots is_stm_dots (Some(promote_mcode colon)) statement code in
      mkres c (Ast0.Default(def,colon,code)) (promote_mcode def) code
  | Ast0.Case(case,exp,colon,code) ->
      let exp = expression exp in
      let code = dots is_stm_dots (Some(promote_mcode colon)) statement code in
      mkres c (Ast0.Case(case,exp,colon,code)) (promote_mcode case) code
  | Ast0.DisjCase(starter,case_lines,mids,ender) ->
      do_disj c starter case_lines mids ender case_line
	(fun starter case_lines mids ender ->
	  Ast0.DisjCase(starter,case_lines,mids,ender))
  | Ast0.OptCase(case) ->
      let case = case_line case in mkres c (Ast0.OptCase(case)) case case

and statement_dots x = dots is_stm_dots None statement x

(* --------------------------------------------------------------------- *)
(* Function declaration *)

let top_level t =
  match Ast0.unwrap t with
    Ast0.FILEINFO(old_file,new_file) -> t
  | Ast0.DECL(stmt) ->
      let stmt = statement stmt in mkres t (Ast0.DECL(stmt)) stmt stmt
  | Ast0.CODE(rule_elem_dots) ->
      let rule_elem_dots = dots is_stm_dots None statement rule_elem_dots in
      mkres t (Ast0.CODE(rule_elem_dots)) rule_elem_dots rule_elem_dots
  | Ast0.ERRORWORDS(exps) -> t
  | Ast0.OTHER(_) -> failwith "eliminated by top_level"

(* --------------------------------------------------------------------- *)
(* Entry points *)

let compute_lines attachable_or x =
  in_nest_count := 0;
  inherit_attachable := attachable_or;
  List.map top_level x

let compute_statement_lines attachable_or x =
  in_nest_count := 0;
  inherit_attachable := attachable_or;
  statement x

let compute_statement_dots_lines attachable_or x =
  in_nest_count := 0;
  inherit_attachable := attachable_or;
  statement_dots x

