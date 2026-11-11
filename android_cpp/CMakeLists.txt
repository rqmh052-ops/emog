cmake_minimum_required(VERSION 3.22)
project(emojiru_exploit)
enable_language(ASM)

set(JNI_DIR ${CMAKE_CURRENT_SOURCE_DIR})

set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} -I${JNI_DIR}")
set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -I${JNI_DIR} -Wall -Wextra \
    -fno-stack-protector -fomit-frame-pointer")

# ── splicehelper: standalone freestanding binary ──────────────────────────
set(SPLICEHELPER "${JNI_DIR}/splicehelper")
add_custom_command(
    OUTPUT  "${SPLICEHELPER}"
    COMMAND "${CMAKE_C_COMPILER}"
            --target=${CMAKE_C_COMPILER_TARGET}
            --sysroot=${CMAKE_SYSROOT}
            "${JNI_DIR}/splicehelper.c"
            -o "${SPLICEHELPER}"
            -nodefaultlibs -nostartfiles -ffreestanding -static
    COMMAND "${CMAKE_STRIP}" "${SPLICEHELPER}"
    DEPENDS "${JNI_DIR}/splicehelper.c"
    COMMENT "Building splicehelper"
)
add_custom_target(splicehelper_bin DEPENDS "${SPLICEHELPER}")

# ── Main exploit executable (AGP only packages lib*.so) ──────────────────
# DirtyFrag's exp.c reads .ko files from a path supplied at runtime.
# Our ExploitBridge.kt passes the path to the correct .ko from assets.
add_executable(dfroot exp.c libcxx.S elf_parser.c)
add_dependencies(dfroot splicehelper_bin)
set_target_properties(dfroot PROPERTIES
    PREFIX  "lib"
    SUFFIX  ".so"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
set_source_files_properties(exp.c PROPERTIES
    OBJECT_DEPENDS "${SPLICEHELPER}")
target_link_libraries(dfroot log)
target_link_options(dfroot PRIVATE -Wl,-z,max-page-size=16384)

# ── Bootstrap executable ─────────────────────────────────────────────────
add_executable(bootstrap bootstrap.c)
set_target_properties(bootstrap PROPERTIES
    PREFIX  "lib"
    SUFFIX  ".so"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
target_link_options(bootstrap PRIVATE -Wl,-z,max-page-size=16384)

# ── Samsung DMC vault launcher (DirtyFrag addition) ───────────────────────
add_executable(d2launch d2_launch.c)
set_target_properties(d2launch PROPERTIES
    PREFIX  "lib"
    SUFFIX  ".so"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_LIBRARY_OUTPUT_DIRECTORY}")
target_link_options(d2launch PRIVATE -Wl,-z,max-page-size=16384)
