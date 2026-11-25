# SPDX-License-Identifier: Apache-2.0
# Strict C++20 compiler contract shared byte-for-byte by all three repositories.
# Included both from the root CMakeLists.txt and from standalone subprojects,
# so no build entry point can silently use weaker flags.

if(NOT TARGET siebensterne_strict_flags)
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
endif()
