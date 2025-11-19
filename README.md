# FitScript

**Fitscript** é uma linguagem de programação que permite que você organize seus treinos de forma customizada e adaptável.

Veja a apresentação da linguagem [aqui](https://github.com/brunozalc/fitscript/blob/main/FitScript.pdf).

---

## Motivação

Geralmente, treinos de academia são listas estáticas de exercícios, seja no papel, num arquivo PDF ou em um aplicativo de celular, com pouca customização. Essas ferramentas, na maioria das vezes, não levam em consideração seu nível de energia, tempo disponível ou eventuais lesões.

A ideia do Fitscript é fazer com que seja possível programar seus treinos como _scripts_, ao invés de listas. Os exercícios de um treino poderiam ser considerados (ou não) a depender do nível de energia do usuário, tempo disponível ou outras métricas. Por exemplo:

```fitscript
routine "Leg Day" {
    let energy = read_sensor(ENERGY_LEVEL);

    exercise "Squat" { sets: 3; reps: 8; weight: 110kg; }

    if (energy > 7) {
        exercise "Leg Press" { sets: 3; reps: 12; weight: 225kg; }
    }

    loop 3 times {
        exercise "Calf Raises" { sets: 1; reps: 15; }
    }
}
```

**Saída:**

```json
{
  "routine": "Workout Routine",
  "exercises": [
    {
      "name": "Squat",
      "sets": 3,
      "reps": 8,
      "weight": "110kg"
    },
    {
      "name": "Leg Press",
      "sets": 3,
      "reps": 12,
      "weight": "225kg"
    },
    {
      "name": "Calf Raises",
      "sets": 1,
      "reps": 15
    },
    {
      "name": "Calf Raises",
      "sets": 1,
      "reps": 15
    },
    {
      "name": "Calf Raises",
      "sets": 1,
      "reps": 15
    }
  ]
}
```

---

## Uso Rápido

```bash
# 1. Compilar o compilador (Flex + Bison)
make

# 2. Compilar FitScript para assembly
build/fitscript examples/fitscript/leg_day.fit -o output/workout.fasm

# 3. Executar na VM
python3 src/vm.py output/workout.fasm --sensor ENERGY_LEVEL=8

# Ou tudo de uma vez:
build/fitscript examples/fitscript/leg_day.fit -o output/workout.fasm && \
  python3 src/vm.py output/workout.fasm --sensor ENERGY_LEVEL=8

# Rodar os testes
make test
```

---

## Gramática

```ebnf-like
// main
PROGRAM = { STATEMENT } ;

STATEMENT = ROUTINE_DEF | ASSIGNMENT | CONDITIONAL | LOOP | EXERCISE_DEF | STACK_OP ;

// statements
ROUTINE_DEF = "routine" STRING "{" PROGRAM "}" ;

EXERCISE_DEF = "exercise" STRING "{" { PROPERTY_ASSIGNMENT } "}" ;

PROPERTY_ASSIGNMENT = IDENTIFIER ":" VALUE ";" ;

ASSIGNMENT = "let" IDENTIFIER "=" EXPRESSION ";" ;

CONDITIONAL = "if" "(" CONDITION ")" "{" PROGRAM "}" [ "else" "{" PROGRAM "}" ] ;

LOOP = "loop" (NUMBER | IDENTIFIER) "times" "{" PROGRAM "}" ;

STACK_OP = "push" IDENTIFIER ";" | "pop" IDENTIFIER ";" ;

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

## Arquitetura

```diagram
┌─────────────────┐
│  test.fit       │  Código em FitScript
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Flex Lexer     │  Tokenização
│  fitscript.l    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Bison Parser   │  Parse + Geração de Código
│  fitscript.y    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  test.fasm      │  Assembly para FitWatch (.fasm)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  FitWatch VM    │  Execução
│  vm.py          │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  routine.json   │  Saída em JSON
└─────────────────┘
```

---

## Compilador (Flex + Bison)

```bash
make              # Compila flex, bison e gcc
make clean        # Limpa arquivos gerados (build/ e output/)
make test         # Compila e testa o programa
```

### Uso

```bash
# Compilar para assembly
build/fitscript examples/fitscript/leg_day.fit -o output/routine.fasm

# Compilar e mostrar no stdout
build/fitscript examples/fitscript/leg_day.fit
```

---

## FitWatch

FitWatch é uma pequena máquina virtual que representa a lógica de um smartwatch para um treino de academia:

- **2 registradores**: `R0`, `R1`
- **Program Counter**: `PC`
- **Sensores**: Dicionário de valores (ex: `ENERGY_LEVEL`, `HEART_RATE`)
- **Buffer de exercícios**: Lista de saída
- **Stack**: Pilha LIFO para salvar/restaurar registradores (permite recursão)

### Conjunto de Instruções (9 instruções)

| Instrução                | Descrição              | Exemplo                   |
| ------------------------ | ---------------------- | ------------------------- |
| `INC reg`                | Incrementa registrador | `INC R0`                  |
| `DEC reg`                | Decrementa registrador | `DEC R1`                  |
| `JZ reg label`           | Pula se zero           | `JZ R0 end`               |
| `JNZ reg label`          | Pula se não-zero       | `JNZ R1 loop`             |
| `MOV reg value`          | Move valor imediato    | `MOV R0 10`               |
| `SENSOR reg name`        | Lê sensor              | `SENSOR R0 ENERGY_LEVEL`  |
| `PUSH reg`               | Empilha o registrador  | `PUSH R0`                 |
| `POP reg`                | Desempilha em um reg   | `POP R1`                  |
| `EXERCISE name props...` | Adiciona exercício     | `EXERCISE "Squat" sets:3` |
| `HALT`                   | Para execução          | `HALT`                    |

No nível de FitScript, basta usar `push nome_variavel;` e `pop nome_variavel;` para salvar/restaurar registradores antes e depois de blocos recursivos ou loops profundos. Veja `examples/fitscript/stack_example.fit` e `examples/fitscript/recursive_flow.fit` para roteiros completos que usam a pilha.

### Uso da VM

```bash
# Executar assembly diretamente
python3 src/vm.py examples/assembly/routine.fasm

# Com sensores customizados
python3 src/vm.py examples/assembly/routine.fasm --sensor ENERGY_LEVEL=8 --sensor HEART_RATE=120

# Salvar saída JSON
python3 src/vm.py examples/assembly/routine.fasm -o output/workout.json

# Modo debug (mostra cada instrução)
python3 src/vm.py examples/assembly/routine.fasm --debug
```

### Sensores Disponíveis

- `ENERGY_LEVEL` - Nível de energia (0-10)
- `HEART_RATE` - Batimentos por minuto
- `TIME_AVAILABLE` - Tempo disponível (minutos)

Se nenhum sensor for especificado, valores padrão são usados: `ENERGY_LEVEL=5`, `HEART_RATE=100`, `TIME_AVAILABLE=60`.

---

## Como rodar os exemplos?

Você pode encontrar os exemplos no diretório `examples/`:

### Código FitScript (`.fit`) -> Assembly FitWatch (`.fasm`)

```bash
# Treino básico "Leg Day"
build/fitscript examples/fitscript/leg_day.fit -o output/leg_day.fasm

# Exemplo com if-else
build/fitscript examples/fitscript/conditional_example.fit -o output/conditional.fasm

# Exemplo com if-else aninhados
build/fitscript examples/fitscript/if_else_example.fit -o output/if_else.fasm

# Exemplo com pilha (push/pop)
build/fitscript examples/fitscript/stack_example.fit -o output/stack_example.fasm

# Exemplo com fluxo recursivo usando push/pop
build/fitscript examples/fitscript/recursive_flow.fit -o output/recursive_flow.fasm

# Treino completo adaptativo
build/fitscript examples/fitscript/complete_workout.fit -o output/complete.fasm
```

### Assembly FitWatch (`.fasm`) -> JSON

```bash
# Rotina simples (sem lógica)
python3 src/vm.py examples/assembly/simple.fasm

# Rotina com sensor de energia
python3 src/vm.py examples/assembly/routine.fasm --sensor ENERGY_LEVEL=8

# Rotina adaptativa por batimento cardíaco
python3 src/vm.py examples/assembly/heart_rate_adaptive.fasm --sensor HEART_RATE=110

# Rotina baseada em tempo disponível
python3 src/vm.py examples/assembly/time_based.fasm --sensor TIME_AVAILABLE=20
python3 src/vm.py examples/assembly/time_based.fasm --sensor TIME_AVAILABLE=45

# Demonstração de multiplicação
python3 src/vm.py examples/assembly/multiplication.fasm

# Demonstração de pilha (PUSH/POP)
python3 src/vm.py examples/assembly/stack_demo.fasm
```
