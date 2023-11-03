module main

import os

fn detect() string {
	compilers:=[
		"tcc",
		"gcc",
		"clang",
		"icc",
		"pcc",
		"zig",
		"compcert",
		"sdcc",
		"cc"
	] // ordered roughly by speed
	for compiler in compilers {
		if os.exists_in_system_path(compiler) {
			return compiler
		}
	}
	return "no_compiler"
}