#
# Copyright 2020, Intel Corporation
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

cmake_minimum_required(VERSION 3.3)
project(libpmemnew C CXX)

set(VERSION_MAJOR 0)
set(VERSION_MINOR 1)
set(VERSION_PATCH 0)
#set(VERSION_PRERELEASE rc1)

set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
if (VERSION_PATCH GREATER 0)
	set(VERSION ${VERSION}.${VERSION_PATCH})
endif()
if (VERSION_PRERELEASE)
	set(VERSION ${VERSION}-${VERSION_PRERELEASE})
endif()

set(LIBPMEMOBJ_REQUIRED_VERSION 1.8)
set(LIBPMEM_REQUIRED_VERSION 1.7)

set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)

include(FindPerl)
include(FindThreads)
include(CMakeDependentOption)
include(CMakePackageConfigHelpers)
include(CheckCXXSourceCompiles)
include(CheckCXXCompilerFlag)
include(GNUInstallDirs)
include(${CMAKE_SOURCE_DIR}/cmake/functions.cmake)

option(BUILD_EXAMPLES "build examples" ON)
option(BUILD_TESTS "build tests" ON)
option(BUILD_DOC "build documentation" ON)

option(COVERAGE "run coverage test" OFF)
option(DEVELOPER_MODE "enable developer checks" OFF)
option(CHECK_CPP_STYLE "check code style of C++ sources" OFF)
option(TRACE_TESTS "more verbose test outputs" OFF)
option(USE_ASAN "enable AddressSanitizer (debugging)" OFF)
option(USE_UBSAN "enable UndefinedBehaviorSanitizer (debugging)" OFF)

option(TESTS_USE_FORCED_PMEM "run tests with PMEM_IS_PMEM_FORCE=1" OFF)
option(TESTS_USE_VALGRIND "enable tests with valgrind (if found)" ON)
option(TESTS_LONG "enable long running tests" OFF)

# Do not treat include directories from the interfaces
# of consumed Imported Targets as SYSTEM by default.
set(CMAKE_NO_SYSTEM_FROM_IMPORTED 1)

# Required for MSVC to correctly define __cplusplus
add_flag("/Zc:__cplusplus")

set(TEST_DIR ${CMAKE_CURRENT_BINARY_DIR}/test
	CACHE STRING "working directory for tests")

if(NOT CMAKE_BUILD_TYPE)
	set(CMAKE_BUILD_TYPE "Debug")
endif (NOT CMAKE_BUILD_TYPE)

if(EXISTS "${CMAKE_SOURCE_DIR}/.git")
	execute_process(COMMAND git describe
			OUTPUT_VARIABLE SRCVERSION
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
			OUTPUT_STRIP_TRAILING_WHITESPACE
			ERROR_QUIET)
	if(NOT SRCVERSION)
		execute_process(COMMAND git log -1 --format=%h
				OUTPUT_VARIABLE SRCVERSION
				WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
				OUTPUT_STRIP_TRAILING_WHITESPACE)
	endif()
else()
	execute_process(COMMAND cat .version
			OUTPUT_VARIABLE SRCVERSION
			WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
			OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()

if(NOT WIN32)
	find_package(PkgConfig QUIET)
endif()

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/cmake)

if(NOT PERL_FOUND)
	message(FATAL_ERROR "Perl not found")
endif()
if (PERL_VERSION_STRING VERSION_LESS 5.16)
	message(FATAL_ERROR "Too old Perl (<5.16)")
endif()

set(SOURCE_FILES
	src/libpmemnew.c
	src/libpmemnew.h)

add_library(pmemnew SHARED ${SOURCE_FILES})
set_target_properties(pmemnew PROPERTIES SOVERSION 1)
target_link_libraries(pmemnew PRIVATE
	-Wl,--version-script=${CMAKE_SOURCE_DIR}/src/libpmemnew.map)

target_link_libraries(pmemnew PRIVATE ${LIBPMEMOBJ_LIBRARIES})

target_include_directories(pmemnew PRIVATE src/valgrind)

# Enable libpmemnew valgrind annotations
target_compile_options(pmemnew PRIVATE -DLIBPMEMNEW_VG_ENABLED=1)

if(BUILD_TESTS OR BUILD_EXAMPLES)
	if(PKG_CONFIG_FOUND)
		pkg_check_modules(LIBPMEMOBJ REQUIRED libpmemobj>=${LIBPMEMOBJ_REQUIRED_VERSION})
		pkg_check_modules(LIBPMEM REQUIRED libpmem>=${LIBPMEM_REQUIRED_VERSION})
	else()
		find_package(LIBPMEMOBJ REQUIRED ${LIBPMEMOBJ_REQUIRED_VERSION})
		find_package(LIBPMEM REQUIRED ${LIBPMEM_REQUIRED_VERSION})
	endif()

	if (LIBPMEMOBJ_VERSION)
		string(REGEX REPLACE "\\+git.*" "" LIBPMEMOBJ_VERSION_SHORT ${LIBPMEMOBJ_VERSION})
		string(REGEX REPLACE "-rc.*" "" LIBPMEMOBJ_VERSION_SHORT ${LIBPMEMOBJ_VERSION_SHORT})
		string(REPLACE "." ";" VERSION_LIST ${LIBPMEMOBJ_VERSION_SHORT})
		list(GET VERSION_LIST 0 LIBPMEMOBJ_VERSION_MAJOR)
		list(GET VERSION_LIST 1 LIBPMEMOBJ_VERSION_MINOR)
		list(LENGTH VERSION_LIST OBJ_VER_COMPS)
		if (${OBJ_VER_COMPS} LESS 3)
			list(APPEND VERSION_LIST "0")
		endif()
		list(GET VERSION_LIST 2 LIBPMEMOBJ_VERSION_PATCH)
	else()
		message(WARNING "cannot detect libpmemobj version, some tests will be skipped")
		# assume 0.0.0
		set(LIBPMEMOBJ_VERSION_MAJOR 0)
		set(LIBPMEMOBJ_VERSION_MINOR 0)
		set(LIBPMEMOBJ_VERSION_PATCH 0)
	endif()

	math(EXPR LIBPMEMOBJ_VERSION_NUM "${LIBPMEMOBJ_VERSION_PATCH} + ${LIBPMEMOBJ_VERSION_MINOR} * 100 + ${LIBPMEMOBJ_VERSION_MAJOR} * 10000")
endif()

add_executable(check_license EXCLUDE_FROM_ALL utils/check_license/check-license.c)

add_custom_target(checkers ALL)
add_custom_target(cppstyle)
add_custom_target(cppformat)
add_custom_target(check-whitespace)
add_custom_target(check-license
	COMMAND ${CMAKE_SOURCE_DIR}/utils/check_license/check-headers.sh
		${CMAKE_SOURCE_DIR}
		${CMAKE_BINARY_DIR}/check_license
		${CMAKE_SOURCE_DIR}/LICENSE)
add_dependencies(check-license check_license)

add_custom_target(check-whitespace-main
		COMMAND ${PERL_EXECUTABLE}
			${CMAKE_SOURCE_DIR}/utils/check_whitespace
			${CMAKE_SOURCE_DIR}/utils/check_license/*.sh
			${CMAKE_SOURCE_DIR}/README.md)

add_dependencies(check-whitespace check-whitespace-main)

add_custom_target(tests)

if(CHECK_CPP_STYLE)
	find_program(CLANG_FORMAT NAMES clang-format clang-format-9.0)
	set(CLANG_FORMAT_REQUIRED "9.0")
	if(CLANG_FORMAT)
		get_program_version_major_minor(${CLANG_FORMAT} CLANG_FORMAT_VERSION)
		if(NOT (CLANG_FORMAT_VERSION VERSION_EQUAL CLANG_FORMAT_REQUIRED))
			message(FATAL_ERROR "required clang-format version is ${CLANG_FORMAT_REQUIRED} (found version: ${CLANG_FORMAT_VERSION})")
		endif()
	else()
		message(WARNING "clang-format not found - C++ sources will not be checked (required version: ${CLANG_FORMAT_REQUIRED})")
	endif()
endif()

if(DEVELOPER_MODE)
	add_flag(-Werror) # XXX: WX for windows
	execute_process(COMMAND ${PERL_EXECUTABLE} -MText::Diff -e ""
			ERROR_QUIET
			RESULT_VARIABLE PERL_TEXT_DIFF_STATUS)
	if (PERL_TEXT_DIFF_STATUS)
		message(FATAL_ERROR "Text::Diff Perl module not found (install libtext-diff-perl or perl-Text-Diff)")
	endif()

	add_dependencies(checkers cppstyle)
	add_dependencies(checkers check-whitespace)
	add_dependencies(checkers check-license)
endif(DEVELOPER_MODE)

add_cppstyle(src
	${CMAKE_CURRENT_SOURCE_DIR}/src/*.c*
	${CMAKE_CURRENT_SOURCE_DIR}/src/*.h*)
add_check_whitespace(src
	${CMAKE_CURRENT_SOURCE_DIR}/src/*.c*
	${CMAKE_CURRENT_SOURCE_DIR}/src/*.h*)
add_check_whitespace(cmake-main
	${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt)
add_check_whitespace(cmake-helpers
	${CMAKE_CURRENT_SOURCE_DIR}/cmake/*.cmake)

install(DIRECTORY examples/ DESTINATION ${CMAKE_INSTALL_DOCDIR}/examples
	FILES_MATCHING PATTERN "*.[ch]")

configure_file(${CMAKE_SOURCE_DIR}/cmake/libpmemnew.pc.in
	${CMAKE_CURRENT_BINARY_DIR}/libpmemnew.pc @ONLY)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libpmemnew.pc
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

configure_file(
	"${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in"
	"${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
	IMMEDIATE @ONLY)

add_custom_target(uninstall
	COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)

configure_package_config_file(${CMAKE_SOURCE_DIR}/cmake/libpmemnew-config.cmake.in
	${CMAKE_CURRENT_BINARY_DIR}/libpmemnew-config.cmake
	INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/libpmemnew/cmake
	PATH_VARS CMAKE_INSTALL_LIBDIR CMAKE_INSTALL_INCLUDEDIR)

write_basic_package_version_file(libpmemnew-config-version.cmake
				VERSION ${VERSION}
				COMPATIBILITY AnyNewerVersion)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/libpmemnew-config.cmake ${CMAKE_CURRENT_BINARY_DIR}/libpmemnew-config-version.cmake
	DESTINATION ${CMAKE_INSTALL_LIBDIR}/libpmemnew/cmake)

include_directories(include)

if(PKG_CONFIG_FOUND)
	pkg_check_modules(VALGRIND QUIET valgrind)
else()
	find_package(VALGRIND QUIET)
endif()

if(VALGRIND_FOUND)
	add_flag(-DLIBPMEMNEW_VG_MEMCHECK_ENABLED=1)
	add_flag(-DLIBPMEMNEW_VG_DRD_ENABLED=1)
	add_flag(-DLIBPMEMNEW_VG_HELGRIND_ENABLED=1)

	include_directories(${VALGRIND_INCLUDE_DIRS})
	find_pmemcheck()

	if(VALGRIND_PMEMCHECK_FOUND)
		add_flag(-DLIBPMEMNEW_VG_PMEMCHECK_ENABLED=1)
	endif()
endif()

if(BUILD_TESTS)
	if(TEST_DIR)
		enable_testing()
	else()
		message(WARNING "TEST_DIR is empty - 'make test' will not work")
	endif()

	add_subdirectory(tests)
endif()

if(BUILD_DOC)
	add_subdirectory(doc)
endif()

if(BUILD_EXAMPLES)
	add_subdirectory(examples)
endif()

if(NOT "${CPACK_GENERATOR}" STREQUAL "")
	include(${CMAKE_SOURCE_DIR}/cmake/packages.cmake)
endif()
