module main

import os

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



fn (mut l LiveC) function(defline string) {
	l.spaces+=2
	mut source:="
	"
	mut inp:=""
	for inp!="}" {
		source+=inp+"\n"
		inp=os.input("...${" ".repeat(l.spaces*2)}")
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
			mut inp:=os.input("...${" ".repeat(l.spaces*2)}")
			if inp.contains_only("} ") {
				temp:="...${" ".repeat((l.spaces*2)-(1+first.len))}}"
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
		x.statement(os.input("$~ "))
	}
}
