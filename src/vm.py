#!/usr/bin/env python3

import argparse
import json
import sys
from dataclasses import dataclass
from typing import Any, Dict, List


@dataclass
class Exercise:
    name: str
    properties: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return {"name": self.name, **self.properties}


class FitWatchVM:
    """
    FitWatch VM

    Architecture:
    - 2 general-purpose registers: R0, R1
    - Program counter (PC)
    - Sensor inputs (dictionary)
    - Exercise output buffer (list)

    Instruction Set (Turing Complete):
    1. INC reg          - Increment register by 1
    2. DEC reg          - Decrement register by 1 (stops at 0)
    3. JZ reg label     - Jump to label if register is zero
    4. JNZ reg label    - Jump to label if register is NOT zero
    5. MOV reg value    - Load immediate value into register
    6. SENSOR reg name  - Read sensor value into register
    7. EXERCISE name props... - Add exercise to routine output
    """

    def __init__(self, debug: bool = False):
        self.registers = {"R0": 0, "R1": 0}
        self.pc = 0
        self.sensors: Dict[str, int] = {}
        self.exercises: List[Exercise] = []
        self.labels: Dict[str, int] = {}
        self.program: List[str] = []
        self.debug = debug
        self.cycle_count = 0

    def set_sensor(self, name: str, value: int) -> None:
        self.sensors[name] = value
        if self.debug:
            print(f"[DEBUG] Set sensor {name} = {value}")

    def load_program(self, filename: str) -> None:
        with open(filename, "r") as f:
            lines = f.readlines()

        # First pass: remove comments and empty lines, find labels
        self.program = []
        for line_num, line in enumerate(lines, 1):
            # Remove comments
            if ";" in line:
                line = line[: line.index(";")]

            line = line.strip()
            if not line:
                continue

            # Check for label (ends with ':')
            if line.endswith(":"):
                label_name = line[:-1].strip()
                self.labels[label_name] = len(self.program)
                if self.debug:
                    print(
                        f"[DEBUG] Found label '{label_name}' at line {len(self.program)}"
                    )
            else:
                self.program.append(line)

        if self.debug:
            print(f"[DEBUG] Loaded {len(self.program)} instructions")
            print(f"[DEBUG] Labels: {self.labels}")

    def parse_instruction(self, instruction: str):
        parts = instruction.split(None, 1)
        opcode = parts[0].upper()
        operands = parts[1] if len(parts) > 1 else ""
        return opcode, operands

    def parse_exercise_props(self, props_str: str) -> Dict[str, Any]:
        props = {}
        if not props_str.strip():
            return props

        # Split by whitespace, then by colon
        for prop in props_str.split():
            if ":" in prop:
                key, value = prop.split(":", 1)
                # Try to convert to int, otherwise keep as string
                try:
                    props[key] = int(value)
                except ValueError:
                    # Remove quotes if present
                    props[key] = value.strip("\"'")

        return props

    def execute_instruction(self, instruction: str) -> bool:
        opcode, operands = self.parse_instruction(instruction)

        if self.debug:
            print(
                f"[DEBUG] PC={self.pc} | {instruction} | R0={self.registers['R0']} R1={self.registers['R1']}"
            )

        # INC reg
        if opcode == "INC":
            reg = operands.strip()
            if reg not in self.registers:
                raise ValueError(f"Invalid register: {reg}")
            self.registers[reg] += 1
            self.pc += 1

        # DEC reg
        elif opcode == "DEC":
            reg = operands.strip()
            if reg not in self.registers:
                raise ValueError(f"Invalid register: {reg}")
            if self.registers[reg] > 0:
                self.registers[reg] -= 1
            self.pc += 1

        # JZ reg label
        elif opcode == "JZ":
            parts = operands.split(None, 1)
            if len(parts) != 2:
                raise ValueError(f"JZ requires register and label: {instruction}")
            reg, label = parts
            if reg not in self.registers:
                raise ValueError(f"Invalid register: {reg}")

            if self.registers[reg] == 0:
                if label not in self.labels:
                    raise ValueError(f"Undefined label: {label}")
                self.pc = self.labels[label]
            else:
                self.pc += 1

        # JNZ reg label
        elif opcode == "JNZ":
            parts = operands.split(None, 1)
            if len(parts) != 2:
                raise ValueError(f"JNZ requires register and label: {instruction}")
            reg, label = parts
            if reg not in self.registers:
                raise ValueError(f"Invalid register: {reg}")

            if self.registers[reg] != 0:
                if label not in self.labels:
                    raise ValueError(f"Undefined label: {label}")
                self.pc = self.labels[label]
            else:
                self.pc += 1

        # MOV reg value
        elif opcode == "MOV":
            parts = operands.split(None, 1)
            if len(parts) != 2:
                raise ValueError(f"MOV requires register and value: {instruction}")
            reg, value_str = parts
            if reg not in self.registers:
                raise ValueError(f"Invalid register: {reg}")

            try:
                value = int(value_str)
            except ValueError:
                raise ValueError(f"MOV value must be an integer: {value_str}")

            self.registers[reg] = value
            self.pc += 1

        # SENSOR reg sensor_name
        elif opcode == "SENSOR":
            parts = operands.split(None, 1)
            if len(parts) != 2:
                raise ValueError(
                    f"SENSOR requires register and sensor name: {instruction}"
                )
            reg, sensor_name = parts
            if reg not in self.registers:
                raise ValueError(f"Invalid register: {reg}")

            if sensor_name not in self.sensors:
                raise ValueError(
                    f"Undefined sensor: {sensor_name}. Available: {list(self.sensors.keys())}"
                )

            self.registers[reg] = self.sensors[sensor_name]
            self.pc += 1

        # EXERCISE "name" props...
        elif opcode == "EXERCISE":
            if not operands:
                raise ValueError(f"EXERCISE requires name: {instruction}")

            if '"' in operands:
                start_quote = operands.index('"')
                end_quote = operands.index('"', start_quote + 1)
                name = operands[start_quote + 1 : end_quote]
                props_str = operands[end_quote + 1 :].strip()
            else:
                parts = operands.split(None, 1)
                name = parts[0]
                props_str = parts[1] if len(parts) > 1 else ""

            props = self.parse_exercise_props(props_str)
            exercise = Exercise(name=name, properties=props)
            self.exercises.append(exercise)

            if self.debug:
                print(f"[DEBUG] Added exercise: {name} with {props}")

            self.pc += 1

        # HALT
        elif opcode == "HALT":
            return False

        else:
            raise ValueError(f"Unknown instruction: {opcode}")

        return True

    def run(self) -> List[Exercise]:
        self.pc = 0
        self.cycle_count = 0

        while self.pc < len(self.program):
            instruction = self.program[self.pc]
            should_continue = self.execute_instruction(instruction)

            if not should_continue:
                break

            self.cycle_count += 1

        if self.debug:
            print(f"[DEBUG] Program completed in {self.cycle_count} cycles")
            print(
                f"[DEBUG] Final registers: R0={self.registers['R0']}, R1={self.registers['R1']}"
            )

        return self.exercises

    def export_routine_json(self, routine_name: str = "Workout Routine") -> str:
        routine = {
            "routine": routine_name,
            "exercises": [ex.to_dict() for ex in self.exercises],
        }
        return json.dumps(routine, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description="FitWatch VM - Execute fitness routine assembly programs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run a program with default sensors
  python3 vm.py examples/routine.fasm

  # Run with custom sensor values
  python3 vm.py examples/routine.fasm --sensor ENERGY_LEVEL=8 --sensor HEART_RATE=120

  # Enable debug mode
  python3 vm.py examples/routine.fasm --debug

  # Export to JSON file
  python3 vm.py examples/routine.fasm --output routine.json
        """,
    )

    parser.add_argument("program", help="FitWatch assembly program file (.fasm)")
    parser.add_argument(
        "--sensor", action="append", help="Set sensor value (format: NAME=VALUE)"
    )
    parser.add_argument("--debug", action="store_true", help="Enable debug output")
    parser.add_argument("--output", "-o", help="Output JSON file (default: stdout)")
    parser.add_argument(
        "--routine-name", default="Workout Routine", help="Name of the routine"
    )

    args = parser.parse_args()

    # Create and configure VM
    vm = FitWatchVM(debug=args.debug)

    # Set sensor values from command line
    if args.sensor:
        for sensor_spec in args.sensor:
            if "=" not in sensor_spec:
                print(f"Error: Invalid sensor format '{sensor_spec}'. Use NAME=VALUE")
                sys.exit(1)
            name, value = sensor_spec.split("=", 1)
            try:
                vm.set_sensor(name, int(value))
            except ValueError:
                print(f"Error: Sensor value must be an integer: {value}")
                sys.exit(1)

    # Set default sensors if none provided
    if not vm.sensors:
        vm.set_sensor("ENERGY_LEVEL", 5)
        vm.set_sensor("HEART_RATE", 100)
        vm.set_sensor("TIME_AVAILABLE", 60)  # minutes

    # Load and run program
    try:
        vm.load_program(args.program)
        vm.run()

        # Export results
        json_output = vm.export_routine_json(args.routine_name)

        if args.output:
            with open(args.output, "w") as f:
                f.write(json_output)
            print(f"Routine exported to {args.output}")
        else:
            print("\n" + "=" * 50)
            print("ROUTINE OUTPUT")
            print("=" * 50)
            print(json_output)

    except FileNotFoundError:
        print(f"Error: Program file not found: {args.program}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        if args.debug:
            raise
        sys.exit(1)


if __name__ == "__main__":
    main()
