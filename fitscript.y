%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int line_num;

void yyerror(const char *s);
%}

%union {
    int num;
    char *str;
}

%token ROUTINE EXERCISE LET IF ELSE LOOP TIMES READ_SENSOR
%token EQ NEQ GT LT GTE LTE
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON COLON ASSIGN
%token <str> IDENTIFIER STRING
%token <num> NUMBER

%start program

%%

program:
    /* empty */
    | statement_list
    ;

statement_list:
    statement
    | statement_list statement
    ;

statement:
    routine_def
    | exercise_def
    | assignment
    | conditional
    | loop
    ;

routine_def:
    ROUTINE STRING LBRACE statement_list RBRACE
    {
        printf("Parsed routine: %s\n", $2);
        free($2);
    }
    | ROUTINE STRING LBRACE RBRACE
    {
        printf("Parsed empty routine: %s\n", $2);
        free($2);
    }
    ;

exercise_def:
    EXERCISE STRING LBRACE property_list RBRACE
    {
        printf("Parsed exercise: %s\n", $2);
        free($2);
    }
    | EXERCISE STRING LBRACE RBRACE
    {
        printf("Parsed exercise with no properties: %s\n", $2);
        free($2);
    }
    ;

property_list:
    property_assignment
    | property_list property_assignment
    ;

property_assignment:
    IDENTIFIER COLON value SEMICOLON
    {
        printf("  Property: %s\n", $1);
        free($1);
    }
    ;

assignment:
    LET IDENTIFIER ASSIGN expression SEMICOLON
    {
        printf("Assignment to variable: %s\n", $2);
        free($2);
    }
    ;

conditional:
    IF LPAREN condition RPAREN LBRACE statement_list RBRACE
    {
        printf("Parsed if statement\n");
    }
    | IF LPAREN condition RPAREN LBRACE statement_list RBRACE ELSE LBRACE statement_list RBRACE
    {
        printf("Parsed if-else statement\n");
    }
    ;

loop:
    LOOP loop_count TIMES LBRACE statement_list RBRACE
    {
        printf("Parsed loop statement\n");
    }
    ;

loop_count:
    NUMBER
    | IDENTIFIER { free($1); }
    ;

condition:
    expression comparison_op expression
    ;

comparison_op:
    EQ | NEQ | GT | LT | GTE | LTE
    ;

expression:
    value
    | IDENTIFIER { free($1); }
    | sensor_read
    ;

sensor_read:
    READ_SENSOR LPAREN IDENTIFIER RPAREN
    {
        printf("Sensor read: %s\n", $3);
        free($3);
    }
    ;

value:
    unit_value
    | NUMBER
    | STRING { free($1); }
    ;

unit_value:
    NUMBER IDENTIFIER
    {
        printf("Unit value: %d %s\n", $1, $2);
        free($2);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error at line %d: %s\n", line_num, s);
}

int main(int argc, char **argv) {
    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (!file) {
            fprintf(stderr, "Could not open file %s\n", argv[1]);
            return 1;
        }
        yyin = file;
    }

    printf("Starting FitScript parser...\n");
    int result = yyparse();

    if (result == 0) {
        printf("\nParsing successful!\n");
    } else {
        printf("\nParsing failed.\n");
    }

    return result;
}
