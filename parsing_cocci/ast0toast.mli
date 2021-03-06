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


val ast0toast :
    string -> Ast_cocci.dependency -> string list (* dropped isos *) ->
      Ast_cocci.exists -> Ast0_cocci.rule -> bool list -> Ast_cocci.ruletype ->
	Ast_cocci.rule
val ast0toast_toplevel : Ast0_cocci.top_level -> Ast_cocci.top_level

val ident : Ast0_cocci.ident -> Ast_cocci.ident
val expression : Ast0_cocci.expression -> Ast_cocci.expression
val expression_dots :
    Ast0_cocci.expression Ast0_cocci.dots ->
      Ast_cocci.expression Ast_cocci.dots
val initialiser : Ast0_cocci.initialiser -> Ast_cocci.initialiser
val statement : Ast0_cocci.statement -> Ast_cocci.statement
val statement_dots :
    Ast0_cocci.statement Ast0_cocci.dots -> Ast_cocci.statement Ast_cocci.dots
val declaration_dots :
    Ast0_cocci.declaration Ast0_cocci.dots ->
      Ast_cocci.declaration Ast_cocci.dots
val case_line : Ast0_cocci.case_line -> Ast_cocci.case_line
val typeC : Ast0_cocci.typeC -> Ast_cocci.fullType
val declaration : Ast0_cocci.declaration -> Ast_cocci.declaration
val parameterTypeDef :
    Ast0_cocci.parameterTypeDef -> Ast_cocci.parameterTypeDef
val parameter_list : Ast0_cocci.parameter_list -> Ast_cocci.parameter_list
val top_level : Ast0_cocci.top_level -> Ast_cocci.top_level
val mcode : 'a Ast0_cocci.mcode -> 'a Ast_cocci.mcode
val convert_info : Ast0_cocci.info -> Ast_cocci.info
