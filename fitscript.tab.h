/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     ROUTINE = 258,
     EXERCISE = 259,
     LET = 260,
     IF = 261,
     ELSE = 262,
     LOOP = 263,
     TIMES = 264,
     READ_SENSOR = 265,
     EQ = 266,
     NEQ = 267,
     GT = 268,
     LT = 269,
     GTE = 270,
     LTE = 271,
     LBRACE = 272,
     RBRACE = 273,
     LPAREN = 274,
     RPAREN = 275,
     SEMICOLON = 276,
     COLON = 277,
     ASSIGN = 278,
     IDENTIFIER = 279,
     STRING = 280,
     NUMBER = 281
   };
#endif
/* Tokens.  */
#define ROUTINE 258
#define EXERCISE 259
#define LET 260
#define IF 261
#define ELSE 262
#define LOOP 263
#define TIMES 264
#define READ_SENSOR 265
#define EQ 266
#define NEQ 267
#define GT 268
#define LT 269
#define GTE 270
#define LTE 271
#define LBRACE 272
#define RBRACE 273
#define LPAREN 274
#define RPAREN 275
#define SEMICOLON 276
#define COLON 277
#define ASSIGN 278
#define IDENTIFIER 279
#define STRING 280
#define NUMBER 281




#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 14 "fitscript.y"
{
    int num;
    char *str;
}
/* Line 1529 of yacc.c.  */
#line 106 "fitscript.tab.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;

