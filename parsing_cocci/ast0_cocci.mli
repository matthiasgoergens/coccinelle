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


(* --------------------------------------------------------------------- *)
(* Modified code *)

type arity = OPT | UNIQUE | NONE

type token_info =
    { tline_start : int; tline_end : int;
      left_offset : int; right_offset : int }
val default_token_info : token_info

type mcodekind =
    MINUS       of (Ast_cocci.anything list list * token_info) ref
  | PLUS        of Ast_cocci.count
  | CONTEXT     of (Ast_cocci.anything Ast_cocci.befaft *
		      token_info * token_info) ref
  | MIXED       of (Ast_cocci.anything Ast_cocci.befaft *
		      token_info * token_info) ref

type position_info = { line_start : int; line_end : int;
		       logical_start : int; logical_end : int;
		       column : int; offset : int; }

type info = { pos_info : position_info;
	      attachable_start : bool; attachable_end : bool;
	      mcode_start : mcodekind list; mcode_end : mcodekind list;
	      (* the following are only for + code *)
	      strings_before : (Ast_cocci.added_string * position_info) list;
	      strings_after : (Ast_cocci.added_string * position_info) list }

type 'a mcode =
    'a * arity * info * mcodekind * meta_pos ref (* pos, - only *) *
      int (* adjacency_index *)

and 'a wrap =
    { node : 'a;
      info : info;
      index : int ref;
      mcodekind : mcodekind ref;
      exp_ty : Type_cocci.typeC option ref; (* only for expressions *)
      bef_aft : dots_bef_aft; (* only for statements *)
      true_if_arg : bool; (* true if "arg_exp", only for exprs *)
      true_if_test : bool; (* true if "test position", only for exprs *)
      true_if_test_exp : bool;(* true if "test_exp from iso", only for exprs *)
      (*nonempty if this represents the use of an iso*)
      iso_info : (string*anything) list }

and dots_bef_aft =
    NoDots | AddingBetweenDots of statement | DroppingBetweenDots of statement

(* for iso metavariables, true if they can only match nonmodified, unitary
   metavariables
   for SP metavariables, true if the metavariable is unitary (valid up to
   isomorphism phase only) *)
and pure = Impure | Pure | Context | PureContext (* pure and only context *)

(* --------------------------------------------------------------------- *)
(* --------------------------------------------------------------------- *)
(* Dots *)

and 'a base_dots =
    DOTS of 'a list
  | CIRCLES of 'a list
  | STARS of 'a list

and 'a dots = 'a base_dots wrap

(* --------------------------------------------------------------------- *)
(* Identifier *)

and base_ident =
    Id            of string mcode
  | MetaId        of Ast_cocci.meta_name mcode * Ast_cocci.idconstraint * pure
  | MetaFunc      of Ast_cocci.meta_name mcode * Ast_cocci.idconstraint * pure
  | MetaLocalFunc of Ast_cocci.meta_name mcode * Ast_cocci.idconstraint * pure
  | DisjId        of string mcode * ident list *
                     string mcode list (* the |s *) * string mcode
  | OptIdent      of ident
  | UniqueIdent   of ident

and ident = base_ident wrap

(* --------------------------------------------------------------------- *)
(* Expression *)

and base_expression =
    Ident          of ident
  | Constant       of Ast_cocci.constant mcode
  | FunCall        of expression * string mcode (* ( *) *
                      expression dots * string mcode (* ) *)
  | Assignment     of expression * Ast_cocci.assignOp mcode * expression *
	              bool (* true if it can match an initialization *)
  | CondExpr       of expression * string mcode (* ? *) * expression option *
	              string mcode (* : *) * expression
  | Postfix        of expression * Ast_cocci.fixOp mcode
  | Infix          of expression * Ast_cocci.fixOp mcode
  | Unary          of expression * Ast_cocci.unaryOp mcode
  | Binary         of expression * Ast_cocci.binaryOp mcode * expression
  | Nested         of expression * Ast_cocci.binaryOp mcode * expression
  | Paren          of string mcode (* ( *) * expression *
                      string mcode (* ) *)
  | ArrayAccess    of expression * string mcode (* [ *) * expression *
	              string mcode (* ] *)
  | RecordAccess   of expression * string mcode (* . *) * ident
  | RecordPtAccess of expression * string mcode (* -> *) * ident
  | Cast           of string mcode (* ( *) * typeC * string mcode (* ) *) *
                      expression
  | SizeOfExpr     of string mcode (* sizeof *) * expression
  | SizeOfType     of string mcode (* sizeof *) * string mcode (* ( *) *
                      typeC * string mcode (* ) *)
  | TypeExp        of typeC
  | MetaErr        of Ast_cocci.meta_name mcode * constraints * pure
  | MetaExpr       of Ast_cocci.meta_name mcode * constraints *
	              Type_cocci.typeC list option * Ast_cocci.form * pure
  | MetaExprList   of Ast_cocci.meta_name mcode (* only in arglists *) *
	              listlen * pure
  | EComma         of string mcode (* only in arglists *)
  | DisjExpr       of string mcode * expression list * string mcode list *
	              string mcode
  | NestExpr       of string mcode * expression dots * string mcode *
	              expression option * Ast_cocci.multi
  | Edots          of string mcode (* ... *) * expression option
  | Ecircles       of string mcode (* ooo *) * expression option
  | Estars         of string mcode (* *** *) * expression option
  | OptExp         of expression
  | UniqueExp      of expression

and expression = base_expression wrap

and constraints =
    NoConstraint
  | NotIdCstrt     of Ast_cocci.reconstraint
  | NotExpCstrt    of expression list
  | SubExpCstrt    of Ast_cocci.meta_name list

and listlen =
    MetaListLen of Ast_cocci.meta_name mcode
  | CstListLen of int
  | AnyListLen

(* --------------------------------------------------------------------- *)
(* Types *)

and base_typeC =
    ConstVol        of Ast_cocci.const_vol mcode * typeC
  | BaseType        of Ast_cocci.baseType * string mcode list
  | Signed          of Ast_cocci.sign mcode * typeC option
  | Pointer         of typeC * string mcode (* * *)
  | FunctionPointer of typeC *
	          string mcode(* ( *)*string mcode(* * *)*string mcode(* ) *)*
                  string mcode (* ( *)*parameter_list*string mcode(* ) *)
  | FunctionType    of typeC option *
	               string mcode (* ( *) * parameter_list *
                       string mcode (* ) *)
  | Array           of typeC * string mcode (* [ *) *
	               expression option * string mcode (* ] *)
  | EnumName        of string mcode (*enum*) * ident option (* name *)
  | EnumDef  of typeC (* either StructUnionName or metavar *) *
	string mcode (* { *) * expression dots * string mcode (* } *)
  | StructUnionName of Ast_cocci.structUnion mcode * ident option (* name *)
  | StructUnionDef  of typeC (* either StructUnionName or metavar *) *
	string mcode (* { *) * declaration dots * string mcode (* } *)
  | TypeName        of string mcode
  | MetaType        of Ast_cocci.meta_name mcode * pure
  | DisjType        of string mcode * typeC list * (* only after iso *)
                       string mcode list (* the |s *)  * string mcode
  | OptType         of typeC
  | UniqueType      of typeC

and typeC = base_typeC wrap

(* --------------------------------------------------------------------- *)
(* Variable declaration *)
(* Even if the Cocci program specifies a list of declarations, they are
   split out into multiple declarations of a single variable each. *)

and base_declaration =
    MetaDecl   of Ast_cocci.meta_name mcode * pure
  | MetaField  of Ast_cocci.meta_name mcode * pure (* structure fields *)
  | Init       of Ast_cocci.storage mcode option * typeC * ident *
	string mcode (*=*) * initialiser * string mcode (*;*)
  | UnInit     of Ast_cocci.storage mcode option * typeC * ident *
	string mcode (* ; *)
  | TyDecl of typeC * string mcode (* ; *)
  | MacroDecl of ident (* name *) * string mcode (* ( *) *
        expression dots * string mcode (* ) *) * string mcode (* ; *)
  | Typedef of string mcode (* typedef *) * typeC * typeC * string mcode (*;*)
  | DisjDecl   of string mcode * declaration list * string mcode list *
	          string mcode
  | Ddots      of string mcode (* ... *) * declaration option (* whencode *)
  | OptDecl    of declaration
  | UniqueDecl of declaration

and declaration = base_declaration wrap

(* --------------------------------------------------------------------- *)
(* Initializers *)

and base_initialiser =
    MetaInit of Ast_cocci.meta_name mcode * pure
  | InitExpr of expression
  | InitList of string mcode (*{*) * initialiser_list * string mcode (*}*) *
	bool (* true if ordered, false if unordered *)
  | InitGccExt of
      designator list (* name *) * string mcode (*=*) *
	initialiser (* gccext: *)
  | InitGccName of ident (* name *) * string mcode (*:*) *
	initialiser
  | IComma of string mcode
  | Idots  of string mcode (* ... *) * initialiser option (* whencode *)
  | OptIni    of initialiser
  | UniqueIni of initialiser

and designator =
    DesignatorField of string mcode (* . *) * ident
  | DesignatorIndex of string mcode (* [ *) * expression * string mcode (* ] *)
  | DesignatorRange of
      string mcode (* [ *) * expression * string mcode (* ... *) *
      expression * string mcode (* ] *)

and initialiser = base_initialiser wrap

and initialiser_list = initialiser dots

(* --------------------------------------------------------------------- *)
(* Parameter *)

and base_parameterTypeDef =
    VoidParam     of typeC
  | Param         of typeC * ident option
  | MetaParam     of Ast_cocci.meta_name mcode * pure
  | MetaParamList of Ast_cocci.meta_name mcode * listlen * pure
  | PComma        of string mcode
  | Pdots         of string mcode (* ... *)
  | Pcircles      of string mcode (* ooo *)
  | OptParam      of parameterTypeDef
  | UniqueParam   of parameterTypeDef

and parameterTypeDef = base_parameterTypeDef wrap

and parameter_list = parameterTypeDef dots

(* --------------------------------------------------------------------- *)
(* #define Parameters *)

and base_define_param =
    DParam        of ident
  | DPComma       of string mcode
  | DPdots        of string mcode (* ... *)
  | DPcircles     of string mcode (* ooo *)
  | OptDParam     of define_param
  | UniqueDParam  of define_param

and define_param = base_define_param wrap

and base_define_parameters =
    NoParams
  | DParams      of string mcode(*( *) * define_param dots * string mcode(* )*)

and define_parameters = base_define_parameters wrap

(* --------------------------------------------------------------------- *)
(* Statement*)

and base_statement =
    Decl          of (info * mcodekind) (* before the decl *) * declaration
  | Seq           of string mcode (* { *) * statement dots *
 	             string mcode (* } *)
  | ExprStatement of expression * string mcode (*;*)
  | IfThen        of string mcode (* if *) * string mcode (* ( *) *
	             expression * string mcode (* ) *) *
	             statement * (info * mcodekind)
  | IfThenElse    of string mcode (* if *) * string mcode (* ( *) *
	             expression * string mcode (* ) *) *
	             statement * string mcode (* else *) * statement *
	             (info * mcodekind)
  | While         of string mcode (* while *) * string mcode (* ( *) *
	             expression * string mcode (* ) *) *
	             statement * (info * mcodekind) (* after info *)
  | Do            of string mcode (* do *) * statement *
                     string mcode (* while *) * string mcode (* ( *) *
	             expression * string mcode (* ) *) *
                     string mcode (* ; *)
  | For           of string mcode (* for *) * string mcode (* ( *) *
                     expression option * string mcode (*;*) *
	             expression option * string mcode (*;*) *
                     expression option * string mcode (* ) *) * statement *
	             (info * mcodekind) (* after info *)
  | Iterator      of ident (* name *) * string mcode (* ( *) *
	             expression dots * string mcode (* ) *) *
	             statement * (info * mcodekind) (* after info *)
  | Switch        of string mcode (* switch *) * string mcode (* ( *) *
	             expression * string mcode (* ) *) * string mcode (* { *) *
	             statement (*decl*) dots *
	             case_line dots * string mcode (* } *)
  | Break         of string mcode (* break *) * string mcode (* ; *)
  | Continue      of string mcode (* continue *) * string mcode (* ; *)
  | Label         of ident * string mcode (* : *)
  | Goto          of string mcode (* goto *) * ident * string mcode (* ; *)
  | Return        of string mcode (* return *) * string mcode (* ; *)
  | ReturnExpr    of string mcode (* return *) * expression *
	             string mcode (* ; *)
  | MetaStmt      of Ast_cocci.meta_name mcode * pure
  | MetaStmtList  of Ast_cocci.meta_name mcode (*only in statement lists*) *
	             pure
  | Exp           of expression  (* only in dotted statement lists *)
  | TopExp        of expression (* for macros body *)
  | Ty            of typeC (* only at top level *)
  | TopInit       of initialiser (* only at top level *)
  | Disj          of string mcode * statement dots list * string mcode list *
	             string mcode
  | Nest          of string mcode * statement dots * string mcode *
	             (statement dots,statement) whencode list * Ast_cocci.multi
  | Dots          of string mcode (* ... *) *
                     (statement dots,statement) whencode list
  | Circles       of string mcode (* ooo *) *
	             (statement dots,statement) whencode list
  | Stars         of string mcode (* *** *) *
	             (statement dots,statement) whencode list
  | FunDecl of (info * mcodekind) (* before the function decl *) *
	fninfo list * ident (* name *) *
	string mcode (* ( *) * parameter_list * string mcode (* ) *) *
	string mcode (* { *) * statement dots *
	string mcode (* } *)
  | Include of string mcode (* #include *) * Ast_cocci.inc_file mcode(* file *)
  | Undef of string mcode (* #define *) * ident (* name *)
  | Define of string mcode (* #define *) * ident (* name *) *
	define_parameters (*params*) * statement dots
  | OptStm   of statement
  | UniqueStm of statement

and fninfo =
    FStorage of Ast_cocci.storage mcode
  | FType of typeC
  | FInline of string mcode
  | FAttr of string mcode

and ('a,'b) whencode =
    WhenNot of 'a
  | WhenAlways of 'b
  | WhenModifier of Ast_cocci.when_modifier
  | WhenNotTrue of expression
  | WhenNotFalse of expression

and statement = base_statement wrap

and base_case_line =
    Default of string mcode (* default *) * string mcode (*:*) * statement dots
  | Case of string mcode (* case *) * expression * string mcode (*:*) *
	statement dots
  | DisjCase of string mcode * case_line list *
	string mcode list (* the |s *) * string mcode
  | OptCase of case_line

and case_line = base_case_line wrap

(* --------------------------------------------------------------------- *)
(* Positions *)

and meta_pos =
    MetaPos of Ast_cocci.meta_name mcode * Ast_cocci.meta_name list *
	Ast_cocci.meta_collect
  | NoMetaPos

(* --------------------------------------------------------------------- *)
(* Top-level code *)

and base_top_level =
    DECL of statement
  | CODE of statement dots
  | FILEINFO of string mcode (* old file *) * string mcode (* new file *)
  | ERRORWORDS of expression list
  | OTHER of statement (* temporary, disappears after top_level.ml *)

and top_level = base_top_level wrap
and rule = top_level list

and parsed_rule =
    CocciRule of
      (rule * Ast_cocci.metavar list *
	 (string list * string list * Ast_cocci.dependency * string *
	    Ast_cocci.exists)) *
	(rule * Ast_cocci.metavar list) * Ast_cocci.ruletype
  | ScriptRule of string (* name *) *
      string * Ast_cocci.dependency *
	(Ast_cocci.script_meta_name *
	   Ast_cocci.meta_name * Ast_cocci.metavar) list (*inherited vars*) *
	Ast_cocci.meta_name list (*script vars*) *
	string
  | InitialScriptRule of string (* name *) *
      string (*language*) * Ast_cocci.dependency * string (*code*)
  | FinalScriptRule of string (* name *) *
      string (*language*) * Ast_cocci.dependency * string (*code*)

(* --------------------------------------------------------------------- *)

and anything =
    DotsExprTag of expression dots
  | DotsInitTag of initialiser dots
  | DotsParamTag of parameterTypeDef dots
  | DotsStmtTag of statement dots
  | DotsDeclTag of declaration dots
  | DotsCaseTag of case_line dots
  | IdentTag of ident
  | ExprTag of expression
  | ArgExprTag of expression  (* for isos *)
  | TestExprTag of expression (* for isos *)
  | TypeCTag of typeC
  | ParamTag of parameterTypeDef
  | InitTag of initialiser
  | DeclTag of declaration
  | StmtTag of statement
  | CaseLineTag of case_line
  | TopTag of top_level
  | IsoWhenTag of Ast_cocci.when_modifier (*only for when code, in iso phase*)
  | IsoWhenTTag of expression(*only for when code, in iso phase*)
  | IsoWhenFTag of expression(*only for when code, in iso phase*)
  | MetaPosTag of meta_pos (* only in iso phase *)

val dotsExpr : expression dots -> anything
val dotsInit : initialiser dots -> anything
val dotsParam : parameterTypeDef dots -> anything
val dotsStmt : statement dots -> anything
val dotsDecl : declaration dots -> anything
val dotsCase : case_line dots -> anything
val ident : ident -> anything
val expr : expression -> anything
val typeC : typeC -> anything
val param : parameterTypeDef -> anything
val ini : initialiser -> anything
val decl : declaration -> anything
val stmt : statement -> anything
val case_line : case_line -> anything
val top : top_level -> anything

(* --------------------------------------------------------------------- *)

val undots : 'a dots -> 'a list

(* --------------------------------------------------------------------- *)
(* Avoid cluttering the parser.  Calculated in compute_lines.ml. *)

val default_info : unit -> info
val default_befaft : unit -> mcodekind
val context_befaft : unit -> mcodekind
val wrap : 'a -> 'a wrap
val context_wrap : 'a -> 'a wrap
val unwrap : 'a wrap -> 'a
val unwrap_mcode : 'a mcode -> 'a
val rewrap : 'a wrap -> 'b -> 'b wrap
val rewrap_mcode : 'a mcode -> 'b -> 'b mcode
val copywrap : 'a wrap -> 'b -> 'b wrap
val get_pos : 'a mcode -> meta_pos
val get_pos_ref : 'a mcode -> meta_pos ref
val set_pos : meta_pos -> 'a mcode -> 'a mcode
val get_info : 'a wrap -> info
val set_info : 'a wrap -> info -> 'a wrap
val get_index : 'a wrap -> int
val set_index : 'a wrap -> int -> unit
val get_line : 'a wrap -> int
val get_line_end : 'a wrap -> int
val get_mcodekind : 'a wrap -> mcodekind
val get_mcode_mcodekind : 'a mcode -> mcodekind
val get_mcodekind_ref : 'a wrap -> mcodekind ref
val set_mcodekind : 'a wrap -> mcodekind -> unit
val set_type : 'a wrap -> Type_cocci.typeC option -> unit
val get_type : 'a wrap -> Type_cocci.typeC option
val set_dots_bef_aft : statement -> dots_bef_aft -> statement
val get_dots_bef_aft : 'a wrap -> dots_bef_aft
val set_arg_exp : expression -> expression
val get_arg_exp : expression -> bool
val set_test_pos : expression -> expression
val get_test_pos : 'a wrap -> bool
val set_test_exp : expression -> expression
val get_test_exp : 'a wrap -> bool
val set_iso : 'a wrap -> (string*anything) list -> 'a wrap
val get_iso : 'a wrap -> (string*anything) list
val fresh_index : unit -> int
val set_mcode_data : 'a -> 'a mcode -> 'a mcode
val make_mcode : 'a -> 'a mcode
val make_mcode_info : 'a -> info -> 'a mcode
val make_minus_mcode : 'a -> 'a mcode

val ast0_type_to_type : typeC -> Type_cocci.typeC
val reverse_type : Type_cocci.typeC -> base_typeC
exception TyConv

val lub_pure : pure -> pure -> pure

(* --------------------------------------------------------------------- *)

val rule_name : string ref (* for the convenience of the parser *)
