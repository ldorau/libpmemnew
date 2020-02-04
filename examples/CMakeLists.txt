#
# Copyright 2018-2020, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#
#     * Neither the name of the copyright holder nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

if(MSVC_VERSION)
	add_flag(-W4)
else()
	add_flag(-Wall)
endif()
add_flag(-Wpointer-arith)
add_flag(-Wsign-compare)
add_flag(-Wunreachable-code-return)
add_flag(-Wmissing-variable-declarations)
add_flag(-fno-common)
#add_flag(-Wunused-macros)
#add_flag(-Wsign-conversion)

add_flag(-ggdb DEBUG)
add_flag(-DDEBUG DEBUG)

add_flag("-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=2" RELEASE)

if(USE_ASAN)
	add_sanitizer_flag(address)
endif()
if(USE_UBSAN)
	add_sanitizer_flag(undefined)
endif()

if(COVERAGE)
       set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -coverage")
endif()

include_directories(${LIBPMEMOBJ_INCLUDE_DIRS} .)
link_directories(${LIBPMEMOBJ_LIBRARY_DIRS})

add_cppstyle(examples-template-example ${CMAKE_CURRENT_SOURCE_DIR}/template-example/*.*pp)
add_check_whitespace(examples-template-example ${CMAKE_CURRENT_SOURCE_DIR}/template-example/*.*pp)

add_cppstyle(examples-doc_snippets ${CMAKE_CURRENT_SOURCE_DIR}/doc_snippets/*.*pp)
add_check_whitespace(examples-doc_snippets ${CMAKE_CURRENT_SOURCE_DIR}/doc_snippets/*.*pp)

function(add_example name)
	set(srcs ${ARGN})
	prepend(srcs ${CMAKE_CURRENT_SOURCE_DIR} ${srcs})
	add_executable(example-${name} ${srcs})
	target_link_libraries(example-${name} ${LIBPMEMOBJ_LIBRARIES} ${CMAKE_THREAD_LIBS_INIT})
endfunction()

if(PKG_CONFIG_FOUND)
	pkg_check_modules(CURSES QUIET ncurses)
else()
	# Specifies that we want FindCurses to find ncurses and not just any
	# curses library
	set(CURSES_NEED_NCURSES TRUE)
	find_package(Curses QUIET)
endif()

if(PKG_CONFIG_FOUND)
	pkg_check_modules(SFML QUIET sfml-all>=2.4)
else()
	# SFML 2.5 has different cmake interface than <= 2.4 so previous versions are not supported
	find_package(SFML 2.5 QUIET COMPONENTS graphics window system)
	set(SFML_LIBRARIES sfml-graphics sfml-window sfml-system)
endif()

if (TEST_ARRAY)
	add_example(queue queue/queue.cpp)
endif()

if (TEST_VECTOR)
	add_example(simplekv simplekv/simplekv.cpp)
	if(NOT CLANG_DESTRUCTOR_REFERENCE_BUG_PRESENT)
		add_example(simplekv_rebuild simplekv_rebuild/simplekv_rebuild.cpp)
	else()
		message(WARNING "skipping simplekv_rebuild example - it requires clang >= ${CLANG_REQUIRED_BY_DESTRUCTOR_REFERENCE_BUG}")
	endif()
endif()

add_example(template-example template-example/template-example.cpp)

add_library(doc_snippets_template-snippet OBJECT doc_snippets/template-snippet.cpp)
