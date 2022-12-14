//
//  main.swift
//  aoc2019
//
//  Created by Rune Holm on 29/10/2022.
//

import Foundation

let OpAdd = 1;
let OpMul = 2;
let OpInput = 3;
let OpOutput = 4;
let OpJmpTrue = 5;
let OpJmpFalse = 6;
let OpLt = 7;
let OpEq = 8;
let OpAdjustRelativeBase = 9;
let OpTerminate = 99;

let ModePos = 0;
let ModeImm = 1;
let ModeRel = 2;


func alu(opcode: Int, a: Int, b: Int) -> Int
{
	switch(opcode)
	{
	case OpAdd:
		return a + b;
	case OpMul:
		return a * b;
	case OpLt:
		return a < b ? 1 : 0;
	case OpEq:
		return a == b ? 1 : 0;
	default:
		fatalError(String(format: "Unknown opcode %x", opcode))
	}
}


typealias Memory = [Int];

func read(memory: Memory, addr: Int) -> Int
{
	if addr < memory.count
	{
		return memory[addr];
	}
	return 0;
}

func write(memory: inout Memory, addr: Int, value: Int) -> ()
{
	if(addr >= memory.count)
	{
		memory.reserveCapacity(addr+1);
		while(addr >= memory.count)
		{
			memory.append(0);
		}
	}
	memory[addr] = value;
}




func read_parameter(memory: Memory, mode: Int, addr: Int, relative_base: Int) -> Int
{
	let param = read(memory:memory, addr:addr);
	switch(mode)
	{
	case ModePos:
		return read(memory:memory, addr:param);
	case ModeImm:
		return param;
	case ModeRel:
		return read(memory:memory, addr:param+relative_base);
	default:
		fatalError(String(format:"Unknown parameter mode %d", mode));
	}
}

func write_addr(memory: Memory, mode: Int, addr: Int, relative_base: Int) -> Int
{
	let param = read(memory:memory, addr:addr);
	switch(mode)
	{
	case ModePos:
		return param;
	case ModeRel:
		return param+relative_base;
	default:
		fatalError(String(format:"Unknown parameter mode %d", mode));
	}
}

func decode_first_word(_ word: Int) -> (Int, Int, Int, Int)
{
	let opcode = word % 100;
	let mode1 = (word /   100)%10;
	let mode2 = (word /  1000)%10;
	let mode3 = (word / 10000)%10;
	return (opcode, mode1, mode2, mode3);
}



func opcode_to_str(_ opcode: Int) -> String
{
	switch(opcode)
	{
	case OpTerminate:
		return "Terminate";
	case OpAdd:
		return "Add";
	case OpMul:
		return "Mul";
	case OpLt:
		return "Lt";
	case OpEq:
		return "Eq";
		
	case OpInput:
		return "Input";

	case OpOutput:
		return "Output";
		
	case OpAdjustRelativeBase:
		return "AdjustRelativeBase";

	case OpJmpTrue:
		return "JmpIfTrue";
	case OpJmpFalse:
		return "JmpIfFalse";

	default:
		return "Unknown";

	}
}

func param_to_str_raw(memory: Memory, mode: Int, addr: Int) -> String
{
	let param = String(read(memory:memory, addr:addr));
	switch(mode)
	{
	case ModePos:
		return String(format:"m[%@]", param);
	case ModeRel:
		return String(format:"m[relative_base+%@]", param);
	case ModeImm:
		return String(format:"%@", param)
	default:
		return "Unknown";
	}
}
func param_to_str(memory: Memory, mode: Int, addr: Int, show_memory:Bool=false, relative_base: Int=Int(0)) -> String
{
	let s = param_to_str_raw(memory:memory, mode: mode, addr: addr);
	if(show_memory)
	{
		let v = read_parameter(memory: memory, mode: mode, addr: addr, relative_base: relative_base)
		return s + "=" + String(v);
	} else {
		return s;
	}
}


func disassemble_instr(memory: Memory, pc: Int, show_memory: Bool=false, relative_base:Int=Int(0)) -> (String, Int)
{
	let (opcode, mode1, mode2, mode3) = decode_first_word(read(memory:memory, addr:pc));
	let param1 = param_to_str(memory: memory, mode: mode1, addr:pc+1, show_memory: show_memory, relative_base: relative_base);
	let param2 = param_to_str(memory: memory, mode: mode2, addr:pc+2, show_memory: show_memory, relative_base: relative_base);
	let param3 = param_to_str(memory: memory, mode: mode3, addr:pc+3);
	let opcode_name = opcode_to_str(opcode);
	switch(opcode)
	{
	case OpTerminate:
		return (opcode_name, pc+1);
	case OpAdd, OpMul, OpLt, OpEq:
		return ("\(opcode_name) \(param3), \(param1), \(param2)", pc+4)
	case OpInput, OpOutput, OpAdjustRelativeBase:
		return ("\(opcode_name) \(param1)", pc+2);

	case OpJmpTrue, OpJmpFalse:
		return ("\(opcode_name) \(param1), \(param2)", pc+3);

	default:
		return (String(format: "Unknown opcode %x, pc %x", opcode, pc), pc+1)

	}

	
}

func make_memory(_ initial_memory: [Int]) -> Memory
{
	return initial_memory.map { Int($0) };
}

func disassemble(memory: [Int])
{
	var pc = Int(0);
	while(pc < memory.count)
	{
		let (disas, next_pc) = disassemble_instr(memory: memory, pc: pc);
		print(String(format:"%04d %@", pc, disas));
		pc = next_pc;
	}
}


func execute(initial_memory: [Int], input: [Int]) -> Int
{
	var input_pos = 0;
	var memory : Memory = make_memory(initial_memory);
	var pc : Int = 0;
	var relative_base : Int = 0;
	while true
	{
		let (opcode, mode1, mode2, mode3) = decode_first_word(read(memory:memory, addr:pc));
		switch(opcode)
		{
		case OpTerminate:
			return read(memory:memory, addr:0);
		case OpAdd, OpMul, OpLt, OpEq:
			let a = read_parameter(memory: memory, mode: mode1, addr: pc+1, relative_base: relative_base);
			let b = read_parameter(memory: memory, mode: mode2, addr: pc+2, relative_base: relative_base);
			let d = write_addr    (memory: memory, mode: mode3, addr: pc+3, relative_base: relative_base);
			let result = alu(opcode: opcode, a: a, b: b);
			write(memory:&memory, addr:d, value:result);
			pc += 4;
		case OpInput:
			let d = write_addr(memory: memory, mode: mode1, addr: pc+1, relative_base: relative_base);
			let result = Int(input[input_pos]);
			input_pos += 1;
			write(memory:&memory, addr:d, value:result);
			pc += 2;

		case OpOutput:
			let a = read_parameter(memory: memory, mode: mode1, addr: pc+1, relative_base: relative_base);
			print("Output: ", a);
			pc += 2;
			
		case OpAdjustRelativeBase:
			let a = read_parameter(memory: memory, mode: mode1, addr: pc+1, relative_base: relative_base);
			relative_base += a;
			pc += 2;

		case OpJmpTrue, OpJmpFalse:
			let a = read_parameter(memory: memory, mode: mode1, addr: pc+1, relative_base: relative_base);
			let b = read_parameter(memory: memory, mode: mode2, addr: pc+2, relative_base: relative_base);
			pc += 3;
			if((opcode == OpJmpTrue && a != 0) || (opcode == OpJmpFalse && a == 0))
			{
				pc = b;
			}

		default:
			fatalError(String(format: "Unknown opcode %x, pc %x", opcode, pc))

		}
	}
	
}

func set_parameters(initial_memory: [Int], noun: Int, verb: Int) -> [Int]
{
	var memory = initial_memory;
	memory[1] = noun;
	memory[2] = verb;
	return memory;
}



let day2_program : [Int] = [1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,6,1,19,1,19,5,23,2,10,23,27,2,27,13,31,1,10,31,35,1,35,9,39,2,39,13,43,1,43,5,47,1,47,6,51,2,6,51,55,1,5,55,59,2,9,59,63,2,6,63,67,1,13,67,71,1,9,71,75,2,13,75,79,1,79,10,83,2,83,9,87,1,5,87,91,2,91,6,95,2,13,95,99,1,99,5,103,1,103,2,107,1,107,10,0,99,2,0,14,0];
print("Day 2a:", execute(initial_memory: set_parameters(initial_memory: day2_program, noun: 12, verb: 2), input:[]))

func search()
{
	for noun in 50...100
	{
		for verb in 0...100
		{
			let result = execute(initial_memory: set_parameters(initial_memory: day2_program, noun: noun, verb: verb), input:[])
			if result == 19690720
			{
				print("Day 2b:", noun*100 + verb)
				return;
			}
		}
	}
}
search();

let day5_program = [3,225,1,225,6,6,1100,1,238,225,104,0,1001,92,74,224,1001,224,-85,224,4,224,1002,223,8,223,101,1,224,224,1,223,224,223,1101,14,63,225,102,19,83,224,101,-760,224,224,4,224,102,8,223,223,101,2,224,224,1,224,223,223,1101,21,23,224,1001,224,-44,224,4,224,102,8,223,223,101,6,224,224,1,223,224,223,1102,40,16,225,1102,6,15,225,1101,84,11,225,1102,22,25,225,2,35,96,224,1001,224,-350,224,4,224,102,8,223,223,101,6,224,224,1,223,224,223,1101,56,43,225,101,11,192,224,1001,224,-37,224,4,224,102,8,223,223,1001,224,4,224,1,223,224,223,1002,122,61,224,1001,224,-2623,224,4,224,1002,223,8,223,101,7,224,224,1,223,224,223,1,195,87,224,1001,224,-12,224,4,224,1002,223,8,223,101,5,224,224,1,223,224,223,1101,75,26,225,1101,6,20,225,1102,26,60,224,101,-1560,224,224,4,224,102,8,223,223,101,3,224,224,1,223,224,223,4,223,99,0,0,0,677,0,0,0,0,0,0,0,0,0,0,0,1105,0,99999,1105,227,247,1105,1,99999,1005,227,99999,1005,0,256,1105,1,99999,1106,227,99999,1106,0,265,1105,1,99999,1006,0,99999,1006,227,274,1105,1,99999,1105,1,280,1105,1,99999,1,225,225,225,1101,294,0,0,105,1,0,1105,1,99999,1106,0,300,1105,1,99999,1,225,225,225,1101,314,0,0,106,0,0,1105,1,99999,108,677,226,224,102,2,223,223,1006,224,329,1001,223,1,223,1108,226,677,224,1002,223,2,223,1006,224,344,101,1,223,223,7,226,677,224,102,2,223,223,1006,224,359,1001,223,1,223,1007,226,677,224,1002,223,2,223,1006,224,374,1001,223,1,223,1108,677,226,224,102,2,223,223,1005,224,389,1001,223,1,223,107,226,226,224,102,2,223,223,1006,224,404,101,1,223,223,1107,226,226,224,1002,223,2,223,1005,224,419,1001,223,1,223,1007,677,677,224,102,2,223,223,1006,224,434,101,1,223,223,1107,226,677,224,1002,223,2,223,1006,224,449,101,1,223,223,107,677,677,224,102,2,223,223,1005,224,464,1001,223,1,223,1008,226,226,224,1002,223,2,223,1005,224,479,101,1,223,223,1007,226,226,224,102,2,223,223,1005,224,494,1001,223,1,223,8,677,226,224,1002,223,2,223,1005,224,509,1001,223,1,223,108,677,677,224,1002,223,2,223,1005,224,524,1001,223,1,223,1008,677,677,224,102,2,223,223,1006,224,539,1001,223,1,223,7,677,226,224,1002,223,2,223,1005,224,554,101,1,223,223,1108,226,226,224,1002,223,2,223,1005,224,569,101,1,223,223,107,677,226,224,102,2,223,223,1005,224,584,101,1,223,223,8,226,226,224,1002,223,2,223,1005,224,599,101,1,223,223,108,226,226,224,1002,223,2,223,1006,224,614,1001,223,1,223,7,226,226,224,102,2,223,223,1006,224,629,1001,223,1,223,1107,677,226,224,102,2,223,223,1005,224,644,101,1,223,223,8,226,677,224,102,2,223,223,1006,224,659,1001,223,1,223,1008,226,677,224,1002,223,2,223,1006,224,674,1001,223,1,223,4,223,99,226];
					


print("Day 5a: ")
let _ = execute(initial_memory: day5_program, input: [1]);


print("Day 5b: ")
let _ = execute(initial_memory: day5_program, input: [5]);


let day9_program = [1102,34463338,34463338,63,1007,63,34463338,63,1005,63,53,1101,3,0,1000,109,988,209,12,9,1000,209,6,209,3,203,0,1008,1000,1,63,1005,63,65,1008,1000,2,63,1005,63,904,1008,1000,0,63,1005,63,58,4,25,104,0,99,4,0,104,0,99,4,17,104,0,99,0,0,1102,1,31,1008,1101,682,0,1027,1101,0,844,1029,1102,29,1,1001,1102,1,22,1014,1101,0,21,1011,1102,428,1,1025,1101,0,433,1024,1101,0,38,1019,1102,1,37,1016,1102,35,1,1017,1102,39,1,1018,1102,32,1,1000,1102,23,1,1012,1102,1,329,1022,1102,26,1,1006,1102,1,24,1003,1102,28,1,1005,1102,36,1,1010,1102,34,1,1004,1101,0,1,1021,1102,326,1,1023,1101,33,0,1015,1101,20,0,1002,1101,0,25,1007,1101,0,853,1028,1102,27,1,1009,1102,1,30,1013,1101,689,0,1026,1102,1,0,1020,109,12,2108,30,-3,63,1005,63,201,1001,64,1,64,1105,1,203,4,187,1002,64,2,64,109,-9,2101,0,6,63,1008,63,29,63,1005,63,227,1001,64,1,64,1106,0,229,4,209,1002,64,2,64,109,-6,1208,5,22,63,1005,63,249,1001,64,1,64,1106,0,251,4,235,1002,64,2,64,109,13,21107,40,41,8,1005,1018,273,4,257,1001,64,1,64,1105,1,273,1002,64,2,64,109,-11,2102,1,8,63,1008,63,25,63,1005,63,299,4,279,1001,64,1,64,1105,1,299,1002,64,2,64,109,15,1205,7,317,4,305,1001,64,1,64,1105,1,317,1002,64,2,64,109,10,2105,1,-1,1105,1,335,4,323,1001,64,1,64,1002,64,2,64,109,-22,1202,1,1,63,1008,63,24,63,1005,63,357,4,341,1106,0,361,1001,64,1,64,1002,64,2,64,109,13,1206,6,373,1106,0,379,4,367,1001,64,1,64,1002,64,2,64,109,11,1206,-6,393,4,385,1105,1,397,1001,64,1,64,1002,64,2,64,109,-32,1208,10,34,63,1005,63,419,4,403,1001,64,1,64,1105,1,419,1002,64,2,64,109,30,2105,1,0,4,425,1106,0,437,1001,64,1,64,1002,64,2,64,109,-28,1207,6,21,63,1005,63,455,4,443,1106,0,459,1001,64,1,64,1002,64,2,64,109,4,2101,0,8,63,1008,63,31,63,1005,63,485,4,465,1001,64,1,64,1105,1,485,1002,64,2,64,109,5,1207,-4,28,63,1005,63,505,1001,64,1,64,1106,0,507,4,491,1002,64,2,64,109,9,21102,41,1,2,1008,1016,39,63,1005,63,531,1001,64,1,64,1106,0,533,4,513,1002,64,2,64,109,-10,1201,4,0,63,1008,63,30,63,1005,63,553,1106,0,559,4,539,1001,64,1,64,1002,64,2,64,109,19,21108,42,41,-4,1005,1019,579,1001,64,1,64,1106,0,581,4,565,1002,64,2,64,109,-26,1201,3,0,63,1008,63,32,63,1005,63,607,4,587,1001,64,1,64,1106,0,607,1002,64,2,64,109,20,1205,3,623,1001,64,1,64,1105,1,625,4,613,1002,64,2,64,109,2,21107,43,42,-1,1005,1018,645,1001,64,1,64,1106,0,647,4,631,1002,64,2,64,109,-11,2102,1,1,63,1008,63,29,63,1005,63,667,1105,1,673,4,653,1001,64,1,64,1002,64,2,64,109,27,2106,0,-8,1001,64,1,64,1105,1,691,4,679,1002,64,2,64,109,-25,2107,25,-4,63,1005,63,713,4,697,1001,64,1,64,1105,1,713,1002,64,2,64,109,-2,21108,44,44,2,1005,1010,735,4,719,1001,64,1,64,1106,0,735,1002,64,2,64,109,11,21101,45,0,-3,1008,1016,45,63,1005,63,757,4,741,1106,0,761,1001,64,1,64,1002,64,2,64,109,-15,1202,3,1,63,1008,63,22,63,1005,63,781,1105,1,787,4,767,1001,64,1,64,1002,64,2,64,109,6,21101,46,0,0,1008,1010,49,63,1005,63,811,1001,64,1,64,1105,1,813,4,793,1002,64,2,64,109,-7,2108,34,1,63,1005,63,835,4,819,1001,64,1,64,1105,1,835,1002,64,2,64,109,15,2106,0,10,4,841,1001,64,1,64,1106,0,853,1002,64,2,64,109,-25,2107,33,7,63,1005,63,873,1001,64,1,64,1106,0,875,4,859,1002,64,2,64,109,7,21102,47,1,10,1008,1010,47,63,1005,63,897,4,881,1105,1,901,1001,64,1,64,4,64,99,21102,1,27,1,21102,915,1,0,1105,1,922,21201,1,12038,1,204,1,99,109,3,1207,-2,3,63,1005,63,964,21201,-2,-1,1,21102,942,1,0,1105,1,922,21202,1,1,-1,21201,-2,-3,1,21101,0,957,0,1106,0,922,22201,1,-1,-2,1106,0,968,22101,0,-2,-2,109,-3,2105,1,0];


print("Day 9a: ")
let _ = execute(initial_memory: day9_program, input: [1]);


print("Day 9b: ")
let _ = execute(initial_memory: day9_program, input: [2]);

