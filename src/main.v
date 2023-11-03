module main

import os
import term
import readline { Readline }

struct Function {
	def string
	source string
}

struct RGB {
	r int
	g int 
	b int
}

struct Highlighter {
	default RGB
	conditional RGB
	numbers RGB
	strings RGB
	brackets1 RGB
	brackets2 RGB
	types RGB
	qualifiers RGB
	other RGB
	macros RGB
	symbols RGB
}

struct LiveC {
	mut:
		functions []Function
		main_func string
		spaces int
		first string
		last string
		hl Highlighter
}
pub fn (h Highlighter) highlight(input string, instring bool) []RGB {
	mut out:=[]RGB{}
	conditionals:=[
		"if",
		"else",
		"while",
		"for",
		"case",
		"default",
		"switch",
		"list"
	]
	types:=[
		"int",
		"float",
		"double",
		"char",
		"void",
		"signed",
		"unsigned",
		"size_t",
		'atomic_bool',
		'atomic_char',
		'atomic_schar',
		'atomic_uchar',
		'atomic_short',
		'atomic_ushort',
		'atomic_int',
		'atomic_uint',
		'atomic_long',
		'atomic_ulong',
		'atomic_llong',
		'atomic_ullong',
		'atomic_char16_t',
		'atomic_char32_t',
		'atomic_wchar_t',
		'atomic_size_t',
		'atomic_ptrdiff_t',
		'atomic_intmax_t',
		'atomic_uintmax_t'
	]
	qualifiers:=[
		"const",
		"volatile",
		"restrict",
		"auto",
		"register",
		"static",
		"extern",
		"thread_local"
	]
	other_keywords:=[
		"struct",
		"union",
		"typedef",
		"enum",
		"typedef"
	]
	macros:=[
		"#define",
		"#if",
		"#endif",
		"#elseif"
		"#include"
		"#ifdef"
		"#ifndef",
		"#error",
		"#pragma"
	]
	symbols:=[
		"&",
		"|",
		"!",
		"%",
		"^",
		"*",
		":",
		";",
		"@",
		"~"
		"<",
		">",
		"?",
		"/",
		"=",
		"-"
	]
	mut current:=""
	mut instr:=instring
	for c in input {
		c_ascii:=c.ascii_str()
		current+=c_ascii
		if c_ascii in ["'","\"","`"] {
			instr=!instr
			out << h.strings
			if !instr {
				current=""
			}
		} else if instr {
			out << h.strings
		} else if current.trim_space() in conditionals {
			for _ in 0..current.len-1 {
				_:=out.pop()
			}
			for _ in current {
				out << h.conditional
			}
			current=""
		} else if current.trim_space() in types {
			for _ in 0..current.len-1 {
				_:=out.pop()
			}
			for _ in current {
				out << h.types
			}
			current=""
		} else if current.trim_space() in qualifiers {
			for _ in 0..current.len-1 {
				_:=out.pop()
			}
			for _ in current {
				out << h.qualifiers
			}
			current=""
		} else if current.trim_space() in other_keywords {
			for _ in 0..current.len-1 {
				_:=out.pop()
			}
			for _ in current {
				out << h.other
			}
			current=""
		} else if current.trim_space() in macros {
			for _ in 0..current.len-1 {
				_:=out.pop()
			}
			for _ in current {
				out << h.macros
			}
			current=""
		} else if c_ascii in ["{","}"] {
			out << h.brackets1
			current=""
		} else if c_ascii in ["(",")","[","]"] {
			out << h.brackets2
			current=""
		} else if c_ascii in ["0","1","2","3","4","5","6","7","8","9"] {
			out << h.numbers
		} else if c_ascii in symbols {
			out << h.symbols
		}else {
			out << h.default
		}

		if c_ascii=="\n" {
			current=""
		}
	}
	return out
}

pub fn (r []RGB) print(s string) {
	mut i:=0
	for rgb in r {
		// print(rgb )
		// println(s[i].ascii_str())
		print(term.rgb(rgb.r, rgb.g, rgb.b, s[i].ascii_str()))
		i+=1
	}
}

fn (mut l LiveC) function(defline string) {
	l.spaces+=2
	mut source:="
	"
	mut inp:=""
	for inp!="}" {
		source+=inp+"\n"
		inp=l.input("${" ".repeat(l.spaces*2)}", false)
		l.check_and_out(inp)
	}
	l.functions << Function{
		def: defline
		source: source
	}
	l.spaces-=2
}

fn is_function(statement string) bool {
	conflicting_keywords:=[
		"for",
		"if",
		"else",
		"while",
		"case",
		"switch"
	]
	first, _ := statement.split_once("(") or { "", "" }
	if first.trim_space() in conflicting_keywords {
		return false
	}
	if statement.contains("(") && statement.contains(")") && statement.contains("{") {
		return true
	}
	return false
}

pub fn (mut l LiveC) source() string {
	mut source:="${l.first}".trim(" ")
	for func in l.functions {
		source+=func.def
		source+=func.source+"}"+"\n"
	}
	source+="int main() {\n"
	source+=l.main_func
	source+="}"
	return source
}


pub fn (l LiveC) input(prompt string, instring bool) string {
    mut read := Readline{}
    read.enable_raw_mode()
    mut out := ""
    mut raw := `\0`
    mut cursor_position := 0

    for raw != `\n` {
        if raw != `\0` && int(raw) != 127 && int(raw) != 8 {
            out += raw.str()
            cursor_position += 1
        }
        temp := "${' '.repeat((l.spaces * 2))}"
        print('\033[F\033[K') // wipe current line
        print(temp)

        l.hl.highlight(out, instring).print(out)
        println("")

        // Move the cursor to the correct position
        cursor_movement := '\033[' + cursor_position.str() + 'C'
        print(cursor_movement)
        print(prompt)

        t := read.read_char() or { panic(err) }

        if t == 27 { // escape
            read.disable_raw_mode()
            exit(0)
        } else if t == 10 || t == 13 { // enter
            read.disable_raw_mode()
			println("")
            return out
        } else if t == 8 || t == 127 { // backspace
            if cursor_position > 0 {
                out = out[..out.len - 1]
                cursor_position -= 1
            }
        }
        raw = rune(t)
    }
    read.disable_raw_mode()
    return out
}

fn (mut l LiveC) check_and_out(statement string) string {
	keywords:=[
		"for",
		"if",
		"else",
		"while",
	]
	first, _ := statement.split_once("(") or { "", "" }
	mut temp_source:=""
	if first.trim_space() in keywords || statement[statement.len-1].ascii_str()=="\\" {
		temp_source+=" ".repeat((l.spaces*2)+2)+statement+"\n"
		l.spaces+=2
		for {
			mut inp:=l.input("${" ".repeat(l.spaces*2)}", statement[statement.len-1].ascii_str()=="\\")
			if inp.contains_only("} ") {
				l.spaces-=2
				temp:="${" ".repeat(l.spaces*2)}"
				print('\033[F\033[K')
				print(temp)
				l.hl.highlight('}', false).print('}')
				println("")
				temp_source+="${" ".repeat(l.spaces*2)}"+"}\n"
				return temp_source
			} else if inp[inp.len-1].ascii_str()==";" {
				temp_source+=inp+"\n"
				l.spaces-=2
				return temp_source
			} else {
				temp_source+=l.check_and_out(inp)+"\n"
			}
		}
		
	}
	return " ".repeat((l.spaces*2)+2)+statement
	
}



pub fn (mut l LiveC) statement(statement string) {
	first, _:=statement.split_once(" ") or { "", "" }
	if is_function(statement.trim_space()) {
		l.function(statement)
	} else if statement=="list" {
		print('\033[F\033[K')
		source:=l.source()
		l.hl.highlight(source, false).print(source)
		println("")
	} else if first=="#include" || first=="#define" {
		l.first+=statement+"\n"
	}
	else {
		main_func_bak:=l.main_func
		l.main_func+=l.check_and_out(statement)+"\n"
		os.write_file("temp.c", l.source()) or { panic(err) }
		output:=os.execute("tcc -w -run temp.c")
		if output.output=="" {
			l.last=""
		} else if output.exit_code==0{
			print('\033[F\033[K')
			println("CC: ${output.output[l.last.len..]}")
			l.last=output.output
		} else{
			l.main_func=main_func_bak
			print('\033[F\033[K')
			println("$?==${output.exit_code}: ${output.output}")
		}
	}
	println("")
}

fn main() {
	mut x:=LiveC{
		spaces: 0,
		first: "
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <errno.h>
#include <assert.h>
#include <malloc.h>
#include <memory.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <inttypes.h>
#include <getopt.h>
#include <math.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
",
		last: "",
		hl: Highlighter{
            default: RGB{
                r: 200,
                g: 200,
                b: 200
            },
            conditional: RGB{
                r: 204,
                g: 0,
                b: 0
            },
            numbers: RGB{
                r: 61,
                g: 114,
                b: 180
            },
            strings: RGB{
                r: 99,
                g: 0,
                b: 186
            },
			brackets1: RGB{
				r: 30,
				g: 203,
				b: 160
			},
			brackets2: RGB{
				r: 230,
				g: 180,
				b: 30
			},
			types: RGB{
				r: 0,
				g: 245,
				b: 120
			},
			qualifiers: RGB{
				r: 0,
				g: 50,
				b: 255
			},
			other: RGB{
				r: 0,
				g: 155,
				b: 255
			},
			macros: RGB{
				r: 255,
				g: 73,
				b: 0
			},
			symbols: RGB{
				r: 0,
				g: 180,
				b: 136
			}

        }
	}
	println("")
	for {
		x.statement(x.input("", false))
	}
}
