module main

import os
import term
import readline { Readline }

struct Function {
	def string
	source string
}

struct LiveC {
	mut:
		functions []Function
		main_func string
		spaces int
		first string
}

struct RGB {
	r int
	g int 
	b int
}

struct Output {
	mut:
		stdout []string
		stdhighlight []RGB
		prompt string
		instance LiveC
}

struct Highlighter {
	default RGB
	conditional RGB
	numbers RGB
	strings RGB
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
	for c in input {
		current+=c.ascii_str()
		if current in conditionals {
			for x in 0..current.len-1 {
				_:=out.pop()
			}
			for counter in current {
				out << h.conditional
			}
			current=""
		} else {
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

pub fn (o Output) input() {
	raw:=os.input(o.prompt)

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
	mut read:=Readline{}
	read.enable_raw_mode()
	mut out:=""
	mut raw:=`\0`
	for raw!=`\n` {
		if raw!=`\0` && int(raw)!=127 && int(raw)!=8 {
			out+=raw.str()
		}
		temp:="${" ".repeat((l.spaces*2))}"
		print('\033[F\033[K')
		print(temp)
		hl:=Highlighter{
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
			}
		}
		hl.highlight(out).print(out)
		println("")
		print(prompt)
		t:=read.read_char() or { panic(err) }
		if t==27 { // escape
			read.disable_raw_mode()
			panic("Goodbye")
		} else if t==10 || t==13 { //enter
			println("")
			read.disable_raw_mode()
			return out
		} else if t==8 || t==127 {
			out=out[..out.len-1]
		}
		raw=rune(t)
		
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
				temp:="${" ".repeat((l.spaces*2)-(1+first.len))}}"
				print('\033[F\033[K')
				println(temp)
				
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
		l.main_func+=l.check_and_out(statement)+"\n"
		os.write_file("temp.c", l.source()) or { panic(err) }
		println(os.execute("tcc -w -run temp.c").output)
	}
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
"
	}
	for {
		x.statement(x.input(""))
	}
}
