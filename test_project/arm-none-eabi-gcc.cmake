set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR ARM)

set(TOOLCHAIN_PREFIX arm-none-eabi-)

# Determine executable suffix based on platform
if(WIN32)
    set(EXECUTABLE_SUFFIX ".exe")
else()
    set(EXECUTABLE_SUFFIX "")
endif()

# Search for toolchain in common locations
# Docker/Linux: /root/build/gnu-tools-for-stm32/install-native/bin
# Windows: STM32CubeIDE installation path
find_program(BINUTILS_PATH ${TOOLCHAIN_PREFIX}gcc 
    HINTS 
        "/root/build/gnu-tools-for-stm32/install-native/bin"
        "C:/ST/STM32CubeIDE_1.19.0/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.13.3.rel1.win32_1.0.0.202411081344/tools/bin"
    NO_CACHE)

if (NOT BINUTILS_PATH)
    message(FATAL_ERROR "ARM GCC toolchain not found")
endif ()

# Extract the directory containing the toolchain binaries
# BINUTILS_PATH is the full path to arm-none-eabi-gcc (e.g., /path/to/bin/arm-none-eabi-gcc)
# ARM_TOOLCHAIN_DIR will be the directory (e.g., /path/to/bin)
get_filename_component(ARM_TOOLCHAIN_DIR ${BINUTILS_PATH} DIRECTORY)
# Without that flag CMake is not able to pass test compilation check
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_C_COMPILER ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc${EXECUTABLE_SUFFIX})
set(CMAKE_ASM_COMPILER ${CMAKE_C_COMPILER})
set(CMAKE_CXX_COMPILER ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}g++${EXECUTABLE_SUFFIX})

# Verify compiler exists
if(NOT EXISTS ${CMAKE_C_COMPILER})
    message(FATAL_ERROR "C compiler not found at: ${CMAKE_C_COMPILER}")
endif()

set(CMAKE_AR ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-ar${EXECUTABLE_SUFFIX})
set(CMAKE_RANLIB ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-ranlib${EXECUTABLE_SUFFIX})

set(CMAKE_OBJCOPY ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objcopy${EXECUTABLE_SUFFIX} CACHE INTERNAL "objcopy tool")
set(CMAKE_SIZE_UTIL ${ARM_TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}size${EXECUTABLE_SUFFIX} CACHE INTERNAL "size tool")

# Don't set CMAKE_SYSROOT - let the compiler use its default sysroot
# The toolchain has libraries installed relative to its bin directory
set(CMAKE_FIND_ROOT_PATH ${BINUTILS_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
