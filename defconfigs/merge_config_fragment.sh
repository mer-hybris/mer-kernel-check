#!/bin/sh

fragment_path=$(realpath $PWD)

cpp_flags="\
	-nostdinc                                  \
	-I${fragment_path} \
	-x assembler-with-cpp \
        -P"



cpp $cpp_flags "$@"
