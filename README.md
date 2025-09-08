# fitscript

**Fitscript** é uma linguagem de programação que permite que você organize seus treinos de forma customizada e adaptável. 

---

## Motivação

Geralmente, treinos de academia são listas estáticas de exercícios, seja no papel, num arquivo PDF ou em um aplicativo de celular, com pouca customização. Essas ferramentas, na maioria das vezes, não levam em consideração seu nível de energia, tempo disponível ou eventuais lesões.

A ideia do Fitscript é fazer com que seja possível programar seus treinos como *scripts*, ao invés de listas. Os exercícios de um treino poderiam ser considerados (ou não) a depender do nível de energia do usuário ou outras métricas. Por exemplo:

```
routine "Leg Day"

let energy = read_sensor(ENERGY_LEVEL);

exercise "Squat" { sets: 3; reps: 8; weight: 110kg; }

if (energy > 7) {
    exercise "Leg Press" { sets: 3; reps: 12; weight: 225kg; };
}
```

## Gramática

```
// main
PROGRAM = { STATEMENT } ;

STATEMENT = ROUTINE_DEF | ASSIGNMENT | CONDITIONAL | LOOP | EXERCISE_DEF ;

// statements
ROUTINE_DEF = "routine" STRING "{" PROGRAM "}" ;

EXERCISE_DEF = "exercise" STRING "{" { PROPERTY_ASSIGNMENT } "}" ;

PROPERTY_ASSIGNMENT = IDENTIFIER ":" VALUE ";" ;

ASSIGNMENT = "let" IDENTIFIER "=" EXPRESSION ";" ;

CONDITIONAL = "if" "(" CONDITION ")" "{" PROGRAM "}" [ "else" "{" PROGRAM "}" ] ;

LOOP = "loop" (NUMBER | IDENTIFIER) "times" "{" PROGRAM "}" ;

// expressões e condicionais
CONDITION = EXPRESSION ("==" | "!=" | ">" | "<" | ">=" | "<=") EXPRESSION ;

EXPRESSION = VALUE | IDENTIFIER | SENSOR_READ ;

SENSOR_READ = "read_sensor" "(" IDENTIFIER ")" ;

// valores e tipos
VALUE = UNIT_VALUE | NUMBER | STRING ;

UNIT_VALUE = NUMBER IDENTIFIER ;

// básico
IDENTIFIER = LETTER { LETTER | DIGIT | "_" } ;
NUMBER = DIGIT { DIGIT } ;
STRING = '"' { CHARACTER } '"' ;
LETTER = "a" | "b" | ... | "z" | "A" | "B" | ... | "Z" ;
DIGIT = "0" | "1" | ... |  "9" ;
CHARACTER = LETTER | DIGIT | " " | ... ;
```
