%{
#include <stdio.h>
#include <stdlib.h>
#include "fitscript.tab.h"

int line_num = 1;
%}

%option noyywrap

%%

[ \t]+                  { /* Skip whitespace */ }
\n                      { line_num++; }

"routine"               { return ROUTINE; }
"exercise"              { return EXERCISE; }
"let"                   { return LET; }
"if"                    { return IF; }
"else"                  { return ELSE; }
"loop"                  { return LOOP; }
"times"                 { return TIMES; }
"read_sensor"           { return READ_SENSOR; }
"push"                  { return PUSH; }
"pop"                   { return POP; }

"=="                    { return EQ; }
"!="                    { return NEQ; }
">="                    { return GTE; }
"<="                    { return LTE; }
">"                     { return GT; }
"<"                     { return LT; }

"{"                     { return LBRACE; }
"}"                     { return RBRACE; }
"("                     { return LPAREN; }
")"                     { return RPAREN; }
";"                     { return SEMICOLON; }
":"                     { return COLON; }
"="                     { return ASSIGN; }

[a-zA-Z][a-zA-Z0-9_]*   {
                            yylval.str = strdup(yytext);
                            return IDENTIFIER;
                        }

[0-9]+                  {
                            yylval.num = atoi(yytext);
                            return NUMBER;
                        }

\"([^\"\\]|\\.)*\"      {
                            yylval.str = strdup(yytext);
                            return STRING;
                        }

"//".*                  { /* Single-line comment */ }

"/*"([^*]|\*+[^*/])*\*+"/"  { /* Multi-line comment */
                                for (int i = 0; i < yyleng; i++) {
                                    if (yytext[i] == '\n') line_num++;
                                }
                            }

.                       {
                            fprintf(stderr, "Unexpected character '%c' at line %d\n", yytext[0], line_num);
                        }

%%
