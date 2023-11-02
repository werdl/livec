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
pub fn (h Highlighter) highlight(input string) []RGB {
	mut out:=[]RGB{}
	conditionals:=[
		"if",
		"else",
		"while",
		"for",
		"case",
		"default",
		"switch"
	]
	mut current:=""
	mut instr:=false
	for c in input {
		c_ascii:=c.ascii_str()
		current+=c_ascii
		if current in conditionals {
			for _ in 0..current.len-1 {
				_:=out.pop()
			}
			for _ in current {
				out << h.conditional
			}
			current=""
		} else if c_ascii in ["{","}"] {
			out << h.brackets1
			current=""
		} else if c_ascii in ["(",")","[","]"] {
			out << h.brackets2
			current=""
		} else if c_ascii in ["'","\"","`"] {
			instr=!instr
			out << h.strings
		} else if instr {
			out << h.strings
		}
		else {
			out << h.default
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
		inp=l.input("${" ".repeat(l.spaces*2)}")
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
	mut source:="${l.first}"
	for func in l.functions {
		source+=func.def
		source+=func.source+"}"+"\n"
	}
	source+="int main() {\n"
	source+=l.main_func
	source+="}"
	return source
}


pub fn (l LiveC) input(prompt string) string {
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

        l.hl.highlight(out).print(out)
        println("")

        // Move the cursor to the correct position
        cursor_movement := '\033[' + cursor_position.str() + 'C'
        print(cursor_movement)
        print(prompt)

        t := read.read_char() or { panic(err) }

        if t == 27 { // escape
            read.disable_raw_mode()
            panic("Goodbye")
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
	if first.trim_space() in keywords {
		l.spaces+=2
		temp_source+=statement+"\n"
		for {
			mut inp:=l.input("${" ".repeat(l.spaces*2)}")
			if inp.contains_only("} ") {
				temp:="${" ".repeat((l.spaces*2)-(1+first.len))}"
				print('\033[F\033[K'.repeat(2))
				print(temp)
				l.hl.highlight('}').print('}')
				println("")
				
				temp_source+="}\n"
				l.spaces-=2
				return temp_source
			} else {
				temp_source+=l.check_and_out(inp)+"\n"
			}
		}
		l.spaces-=2
	}
	return statement
	
}



pub fn (mut l LiveC) statement(statement string) {
	first, _:=statement.split_once(" ") or { "", "" }
	if is_function(statement.trim_space()) {
		l.function(statement)
	} else if statement=="list" {
		println(l.source())
	} else if first=="#include" || first=="#define" {
		l.first+=statement+"\n"
	}
	else {
		main_func_bak:=l.main_func
		l.main_func+=l.check_and_out(statement)+"\n"
		os.write_file("temp.c", l.source()) or { panic(err) }
		output:=os.execute("tcc -w -run temp.c")
		if output.exit_code==0 {
			print('\033[F\033[K')
			println("CC: ${output.output[l.last.len..]}")
			l.last=output.output
		} else {
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
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <math.h>
",
		last: "",
		hl: Highlighter{
            default: RGB{
                r: 45,
                g: 66,
                b: 0
            },
            conditional: RGB{
                r: 204,
                g: 0,
                b: 0
            },
            numbers: RGB{
                r: 61,
                g: 114,
                b: 0
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
			}

        }
	}
	for {
		x.statement(x.input(""))
	}
}
