# SPDX-License-Identifier: Apache-2.0
# Strict C++20 baseline shared byte-for-byte by all three repositories.
# Repository-local C++ targets are discovered automatically; no repository is
# exempt from the compiler contract. The clang-tidy contract lives in
# .clang-tidy and the formatter contract in .clang-format.

cmake_minimum_required(VERSION 3.25)
project(siebensterne_tooling LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(siebensterne_strict_flags INTERFACE)
target_compile_features(siebensterne_strict_flags INTERFACE cxx_std_20)
target_compile_options(siebensterne_strict_flags INTERFACE
  -Wall
  -Wextra
  -Wpedantic
  -Werror
  -Wshadow
  -Wcast-qual
  -Wnon-virtual-dtor
  -Woverloaded-virtual
  -Wunused
  -Wnull-dereference
  -Wformat=2
  -Wimplicit-fallthrough
)

include(CTest)

if(BUILD_TESTING AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/verification/cpp-oracle/CMakeLists.txt")
  add_subdirectory(verification/cpp-oracle)
endif()
