%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

extern int yylex();
extern int yyparse();
extern FILE *yyin;
extern int line_num;

void yyerror(const char *s);

/* Code generation globals */
FILE *output_file = NULL;
int label_counter = 0;
char *current_routine_name = NULL;

/* Variable to register mapping (simple: max 2 variables) */
typedef struct {
    char *name;
    char *reg;  // "R0" or "R1"
} VarReg;

VarReg var_table[2] = {{NULL, "R0"}, {NULL, "R1"}};
int var_count = 0;

/* Helper functions */
void emit(const char *fmt, ...);
void emit_comment(const char *fmt, ...);
char *new_label(const char *prefix);
char *allocate_register(const char *var_name);
char *get_register(const char *var_name);
void reset_codegen();

/* Conditional generation helpers */
void generate_condition_check(const char *var, int op, int value);
void generate_condition_check_with_else(const char *var, int op, int value);
void generate_else_label();
void generate_endif_label();

/* Loop generation helpers */
void start_loop(int is_var, int value, const char *var_name);
void end_loop();

/* Global label stack for nested structures */
char *saved_labels[10];
int saved_label_count = 0;

%}

%union {
    int num;
    char *str;
    struct {
        char *var;      // For identifiers in conditions
        int op;         // Comparison operator
        int value;      // For numbers in conditions
    } cond;
    struct {
        char **props;   // Array of property strings
        int count;      // Number of properties
    } props;
    struct loop_info {
        int is_var;
        int value;
        char *var_name;
    } loop_info;
}

%token ROUTINE EXERCISE LET IF ELSE LOOP TIMES READ_SENSOR PUSH POP
%token EQ NEQ GT LT GTE LTE
%token LBRACE RBRACE LPAREN RPAREN SEMICOLON COLON ASSIGN
%token <str> IDENTIFIER STRING
%token <num> NUMBER

%type <cond> condition
%type <num> comparison_op
%type <loop_info> loop_count

%type <str> expression value unit_value sensor_read property_assignment
%type <props> property_list

%start program

%%

program:
    /* empty */
    | statement_list
    {
        emit("HALT");
    }
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
    | stack_statement
    ;

routine_def:
    ROUTINE STRING LBRACE
    {
        emit_comment("==============================================");
        emit_comment("Routine: %s", $2);
        emit_comment("==============================================");
        current_routine_name = strdup($2);
        free($2);
    }
    statement_list RBRACE
    {
        emit("");
    }
    | ROUTINE STRING LBRACE RBRACE
    {
        emit_comment("Empty routine: %s", $2);
        current_routine_name = strdup($2);
        free($2);
    }
    ;

exercise_def:
    EXERCISE STRING LBRACE property_list RBRACE
    {
        // Emit EXERCISE instruction with properties
        // STRING already contains quotes, so don't add more
        fprintf(output_file, "EXERCISE %s", $2);
        for (int i = 0; i < $4.count; i++) {
            fprintf(output_file, " %s", $4.props[i]);
            free($4.props[i]);
        }
        fprintf(output_file, "\n");
        free($4.props);
        free($2);
    }
    | EXERCISE STRING LBRACE RBRACE
    {
        emit("EXERCISE %s", $2);
        free($2);
    }
    ;

property_list:
    property_assignment
    {
        $$.props = malloc(sizeof(char*) * 10);
        $$.props[0] = $<str>1;
        $$.count = 1;
    }
    | property_list property_assignment
    {
        $$.props = $1.props;
        $$.props[$1.count] = $<str>2;
        $$.count = $1.count + 1;
    }
    ;

property_assignment:
    IDENTIFIER COLON value SEMICOLON
    {
        // Create "key:value" string
        char *prop = malloc(strlen($1) + strlen($3) + 2);
        sprintf(prop, "%s:%s", $1, $3);
        $<str>$ = prop;
        free($1);
        free($3);
    }
    ;

assignment:
    LET IDENTIFIER ASSIGN expression SEMICOLON
    {
        char *reg = allocate_register($2);
        emit_comment("%s = %s", $2, $4);

        // Check if expression is a sensor read or number
        if (strncmp($4, "SENSOR:", 7) == 0) {
            char *sensor = $4 + 7;
            emit("SENSOR %s %s", reg, sensor);
        } else {
            emit("MOV %s %s", reg, $4);
        }

        free($2);
        free($4);
    }
    ;

conditional:
    IF LPAREN condition RPAREN LBRACE
    {
        // Generate comparison - always prepare for potential else
        generate_condition_check_with_else($3.var, $3.op, $3.value);
    }
    statement_list RBRACE else_part
    {
        // Cleanup is done in else_part
        free($3.var);
    }
    ;

else_part:
    /* empty - no else clause */
    {
        // Just emit the else label (which is the endif in this case)
        if (saved_label_count > 0) {
            char *else_label = saved_labels[--saved_label_count];
            emit("%s:", else_label);
            emit("");
            free(else_label);
        }
    }
    | ELSE
    {
        generate_else_label();
    }
    LBRACE statement_list RBRACE
    {
        generate_endif_label();
    }
    ;

loop:
    LOOP loop_count TIMES LBRACE
    {
        start_loop($2.is_var, $2.value, $2.var_name);
        if ($2.is_var && $2.var_name) {
            free($2.var_name);
        }
    }
    statement_list RBRACE
    {
        end_loop();
    }
    ;

stack_statement:
    PUSH IDENTIFIER SEMICOLON
    {
        char *reg = get_register($2);
        if (!reg) {
            fprintf(stderr, "Error: Cannot PUSH undefined variable '%s'\n", $2);
            exit(1);
        }
        emit_comment("push %s", $2);
        emit("PUSH %s", reg);
        free($2);
    }
    | POP IDENTIFIER SEMICOLON
    {
        char *reg = get_register($2);
        if (!reg) {
            reg = allocate_register($2);
        }
        emit_comment("pop %s", $2);
        emit("POP %s", reg);
        free($2);
    }
    ;

loop_count:
    NUMBER
    {
        $$.is_var = 0;
        $$.value = $1;
        $$.var_name = NULL;
    }
    | IDENTIFIER
    {
        $$.is_var = 1;
        $$.value = 0;
        $$.var_name = strdup($1);
        free($1);
    }
    ;

condition:
    IDENTIFIER comparison_op NUMBER
    {
        $$.var = strdup($1);
        $$.op = $2;
        $$.value = $3;
        free($1);
    }
    ;

comparison_op:
    EQ  { $$ = EQ; }
    | NEQ { $$ = NEQ; }
    | GT  { $$ = GT; }
    | LT  { $$ = LT; }
    | GTE { $$ = GTE; }
    | LTE { $$ = LTE; }
    ;

expression:
    value
    {
        $$ = $1;
    }
    | IDENTIFIER
    {
        $$ = strdup($1);
        free($1);
    }
    | sensor_read
    {
        $$ = $1;
    }
    ;

sensor_read:
    READ_SENSOR LPAREN IDENTIFIER RPAREN
    {
        // Return "SENSOR:NAME" to be handled by assignment
        char *result = malloc(strlen($3) + 8);
        sprintf(result, "SENSOR:%s", $3);
        $$ = result;
        free($3);
    }
    ;

value:
    unit_value
    {
        $$ = $1;
    }
    | NUMBER
    {
        char *str = malloc(20);
        sprintf(str, "%d", $1);
        $$ = str;
    }
    | STRING
    {
        $$ = $1;
    }
    ;

unit_value:
    NUMBER IDENTIFIER
    {
        // Create "123kg" style string
        char *str = malloc(20 + strlen($2));
        sprintf(str, "%d%s", $1, $2);
        $$ = str;
        free($2);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Parse error at line %d: %s\n", line_num, s);
}

/* Code generation helper functions */
void emit(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vfprintf(output_file, fmt, args);
    va_end(args);
    fprintf(output_file, "\n");
}

void emit_comment(const char *fmt, ...) {
    va_list args;
    fprintf(output_file, "; ");
    va_start(args, fmt);
    vfprintf(output_file, fmt, args);
    va_end(args);
    fprintf(output_file, "\n");
}

char *new_label(const char *prefix) {
    char *label = malloc(strlen(prefix) + 20);
    sprintf(label, "%s_%d", prefix, label_counter++);
    return label;
}

char *allocate_register(const char *var_name) {
    // Check if already allocated
    for (int i = 0; i < var_count; i++) {
        if (var_table[i].name && strcmp(var_table[i].name, var_name) == 0) {
            return var_table[i].reg;
        }
    }

    // Allocate new
    if (var_count < 2) {
        var_table[var_count].name = strdup(var_name);
        return var_table[var_count++].reg;
    }

    // Reuse R1 if out of registers
    fprintf(stderr, "Warning: Reusing R1 for variable '%s'\n", var_name);
    if (var_table[1].name) free(var_table[1].name);
    var_table[1].name = strdup(var_name);
    return var_table[1].reg;
}

char *get_register(const char *var_name) {
    for (int i = 0; i < var_count; i++) {
        if (var_table[i].name && strcmp(var_table[i].name, var_name) == 0) {
            return var_table[i].reg;
        }
    }
    return NULL;
}

void reset_codegen() {
    label_counter = 0;
    var_count = 0;
    saved_label_count = 0;
    for (int i = 0; i < 2; i++) {
        if (var_table[i].name) {
            free(var_table[i].name);
            var_table[i].name = NULL;
        }
    }
    if (current_routine_name) {
        free(current_routine_name);
        current_routine_name = NULL;
    }
}

void generate_condition_check(const char *var, int op, int value) {
    char *reg = get_register(var);
    if (!reg) {
        fprintf(stderr, "Error: Variable '%s' not defined\n", var);
        exit(1);
    }

    emit_comment("if (%s %s %d)", var, op == GT ? ">" : "==", value);

    if (op == GT) {
        // Generate > comparison
        emit("MOV R1 %d", value);
        char *subtract_label = new_label("subtract");
        emit("%s:", subtract_label);
        emit("JZ R1 check_cond");
        emit("DEC %s", reg);
        emit("DEC R1");
        emit("JNZ R1 %s", subtract_label);
        emit("check_cond:");

        // Jump past the if block if condition is false (reg == 0)
        char *endif_label = new_label("endif");
        emit("JZ %s %s", reg, endif_label);
        saved_labels[saved_label_count++] = endif_label;
    } else if (op == EQ) {
        // Generate == comparison
        emit("MOV R1 %d", value);
        char *subtract_label = new_label("subtract_eq");
        emit("%s:", subtract_label);
        emit("JZ R1 check_eq");
        emit("DEC %s", reg);
        emit("DEC R1");
        emit("JNZ R1 %s", subtract_label);
        emit("check_eq:");

        // Jump past the if block if condition is false (reg != 0)
        char *endif_label = new_label("endif");
        emit("JNZ %s %s", reg, endif_label);
        saved_labels[saved_label_count++] = endif_label;
        free(subtract_label);
    }
}

void generate_condition_check_with_else(const char *var, int op, int value) {
    char *reg = get_register(var);
    if (!reg) {
        fprintf(stderr, "Error: Variable '%s' not defined\n", var);
        exit(1);
    }

    emit_comment("if (%s %s %d)", var, op == GT ? ">" : "==", value);

    if (op == GT) {
        emit("MOV R1 %d", value);
        char *subtract_label = new_label("subtract");
        emit("%s:", subtract_label);
        emit("JZ R1 check_cond");
        emit("DEC %s", reg);
        emit("DEC R1");
        emit("JNZ R1 %s", subtract_label);
        emit("check_cond:");
        free(subtract_label);

        char *else_label = new_label("else");
        emit("JZ %s %s", reg, else_label);
        saved_labels[saved_label_count++] = else_label;
    } else if (op == EQ) {
        emit("MOV R1 %d", value);
        char *subtract_label = new_label("subtract_eq");
        emit("%s:", subtract_label);
        emit("JZ R1 check_eq");
        emit("DEC %s", reg);
        emit("DEC R1");
        emit("JNZ R1 %s", subtract_label);
        emit("check_eq:");
        free(subtract_label);

        char *else_label = new_label("else");
        emit("JNZ %s %s", reg, else_label);
        saved_labels[saved_label_count++] = else_label;
    }
}

void generate_else_label() {
    if (saved_label_count > 0) {
        char *else_label = saved_labels[--saved_label_count];
        char *end_label = new_label("endif");
        emit("MOV R0 1");
        emit("JNZ R0 %s", end_label);
        emit("%s:", else_label);
        free(else_label);
        saved_labels[saved_label_count++] = end_label;
    }
}

void generate_endif_label() {
    if (saved_label_count > 0) {
        char *end_label = saved_labels[--saved_label_count];
        emit("%s:", end_label);
        emit("");
        free(end_label);
    }
}

void start_loop(int is_var, int value, const char *var_name) {
    if (is_var) {
        if (!var_name) {
            fprintf(stderr, "Error: Invalid loop variable\n");
            exit(1);
        }
        char *reg = get_register(var_name);
        if (!reg) {
            fprintf(stderr, "Error: Variable '%s' not defined\n", var_name);
            exit(1);
        }
        emit_comment("loop %s times", var_name);
        emit("PUSH %s", reg);
        emit("POP R0");
    } else {
        emit_comment("loop %d times", value);
        emit("MOV R0 %d", value);
    }
    char *loop_start = new_label("loop_start");
    char *loop_end = new_label("loop_end");
    emit("%s:", loop_start);
    emit("JZ R0 %s", loop_end);
    saved_labels[saved_label_count++] = loop_start;
    saved_labels[saved_label_count++] = loop_end;
}

void end_loop() {
    if (saved_label_count >= 2) {
        char *loop_end = saved_labels[--saved_label_count];
        char *loop_start = saved_labels[--saved_label_count];
        emit("DEC R0");
        emit("JNZ R0 %s", loop_start);
        emit("%s:", loop_end);
        emit("");
        free(loop_start);
        free(loop_end);
    }
}

int main(int argc, char **argv) {
    char *output_filename = NULL;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input.fit> [-o output.fasm]\n", argv[0]);
        return 1;
    }

    // Parse arguments
    FILE *file = fopen(argv[1], "r");
    if (!file) {
        fprintf(stderr, "Could not open file %s\n", argv[1]);
        return 1;
    }
    yyin = file;

    // Check for output file option
    if (argc >= 4 && strcmp(argv[2], "-o") == 0) {
        output_filename = argv[3];
        output_file = fopen(output_filename, "w");
        if (!output_file) {
            fprintf(stderr, "Could not open output file %s\n", output_filename);
            return 1;
        }
    } else {
        output_file = stdout;
    }

    // Emit header
    emit_comment("FitWatch Assembly");
    emit_comment("Generated from: %s", argv[1]);
    emit("");

    // Parse and generate code
    int result = yyparse();

    if (result == 0) {
        if (output_filename) {
            fprintf(stderr, "Compilation successful! Assembly written to %s\n", output_filename);
            fprintf(stderr, "Run with: python3 src/vm.py %s\n", output_filename);
        }
    } else {
        fprintf(stderr, "Compilation failed.\n");
    }

    // Cleanup
    reset_codegen();
    if (output_file != stdout) {
        fclose(output_file);
    }
    fclose(file);

    return result;
}
