#
# This file is part of the WarheadCore Project. See AUTHORS file for Copyright information
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

include(CheckCXXSourceCompiles)

if ((USE_COREPCH OR USE_SCRIPTPCH) AND (CMAKE_C_COMPILER_LAUNCHER STREQUAL "ccache" OR CMAKE_CXX_COMPILER_LAUNCHER STREQUAL "ccache"))
  message(STATUS "Clang: disable pch timestamp when ccache and pch enabled")
  # TODO: for ccache https://github.com/ccache/ccache/issues/539
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Xclang -fno-pch-timestamp")
endif()

# Set build-directive (used in core to tell which buildtype we used)
target_compile_definitions(warhead-compile-option-interface
  INTERFACE
    -D_BUILD_DIRECTIVE="${CMAKE_BUILD_TYPE}")

set(CLANG_EXPECTED_VERSION 10.0.0)

if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS CLANG_EXPECTED_VERSION)
  message(FATAL_ERROR "Clang: WarheadCore requires version ${CLANG_EXPECTED_VERSION} to build but found ${CMAKE_CXX_COMPILER_VERSION}")
else()
  message(STATUS "Clang: Minimum version required is ${CLANG_EXPECTED_VERSION}, found ${CMAKE_CXX_COMPILER_VERSION} - ok!")
endif()

if (WITH_WARNINGS)
  target_compile_options(warhead-warning-interface
    INTERFACE
      -W
      -Wall
      -Wextra
      -Winit-self
      -Wfatal-errors
      -Wno-mismatched-tags
      -Woverloaded-virtual)
  message(STATUS "Clang: All warnings enabled")
endif()

if (WITH_COREDEBUG)
  target_compile_options(warhead-compile-option-interface
    INTERFACE
      -g3)
  message(STATUS "Clang: Debug-flags set (-g3)")
endif()

if (MSAN)
    target_compile_options(warhead-compile-option-interface
            INTERFACE
            -fno-omit-frame-pointer
            -fsanitize=memory
            -fsanitize-memory-track-origins
            -mllvm
            -msan-keep-going=1)

    target_link_options(warhead-compile-option-interface
            INTERFACE
            -fno-omit-frame-pointer
            -fsanitize=memory
            -fsanitize-memory-track-origins)

    message(STATUS "Clang: Enabled Memory Sanitizer MSan")
endif()

if (UBSAN)
    target_compile_options(warhead-compile-option-interface
            INTERFACE
            -fno-omit-frame-pointer
            -fsanitize=undefined)

    target_link_options(warhead-compile-option-interface
            INTERFACE
            -fno-omit-frame-pointer
            -fsanitize=undefined)

    message(STATUS "Clang: Enabled Undefined Behavior Sanitizer UBSan")
endif()

if (TSAN)
    target_compile_options(warhead-compile-option-interface
            INTERFACE
            -fno-omit-frame-pointer
            -fsanitize=thread)

    target_link_options(warhead-compile-option-interface
            INTERFACE
            -fno-omit-frame-pointer
            -fsanitize=thread)

    message(STATUS "Clang: Enabled Thread Sanitizer TSan")
endif()

if (ASAN)
  target_compile_options(warhead-compile-option-interface
    INTERFACE
    -fno-omit-frame-pointer
    -fsanitize=address
    -fsanitize-recover=address
    -fsanitize-address-use-after-scope)

  target_link_options(warhead-compile-option-interface
    INTERFACE
    -fno-omit-frame-pointer
    -fsanitize=address
    -fsanitize-recover=address
    -fsanitize-address-use-after-scope)

  message(STATUS "Clang: Enabled Address Sanitizer")
endif()

# -Wno-narrowing needed to suppress a warning in g3d
# -Wno-deprecated-register is needed to suppress gsoap warnings on Unix systems.
target_compile_options(warhead-compile-option-interface
  INTERFACE
    -Wno-narrowing
    -Wno-deprecated-register)

if (BUILD_SHARED_LIBS)
    # -fPIC is needed to allow static linking in shared libs.
    # -fvisibility=hidden sets the default visibility to hidden to prevent exporting of all symbols.
    target_compile_options(warhead-compile-option-interface
      INTERFACE
        -fPIC)

    target_compile_options(warhead-hidden-symbols-interface
      INTERFACE
        -fvisibility=hidden)

    # --no-undefined to throw errors when there are undefined symbols
    # (caused through missing WARHEAD_*_API macros).
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --no-undefined")

    message(STATUS "Clang: Disallow undefined symbols")
endif()

# speedup PCH builds by forcing template instantiations during PCH generation
set(CMAKE_REQUIRED_FLAGS "-fpch-instantiate-templates")
check_cxx_source_compiles("int main() { return 0; }" CLANG_HAS_PCH_INSTANTIATE_TEMPLATES)
unset(CMAKE_REQUIRED_FLAGS)
if (CLANG_HAS_PCH_INSTANTIATE_TEMPLATES)
  target_compile_options(warhead-compile-option-interface
    INTERFACE
      -fpch-instantiate-templates)

  message(STATUS "Clang: Enable -fpch-instantiate-templates")
endif()