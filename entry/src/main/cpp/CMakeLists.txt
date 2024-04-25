# the minimum version of CMake.
cmake_minimum_required(VERSION 3.4.1)
project(cjglideOpenGl)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include
                    )
add_library(glwrapper SHARED shader_str.h gl_wrapper.h gl_wrapper.cpp)

find_library( # Sets the name of the path variable.
              EGL-lib
              # Specifies the name of the NDK library that
              # you want CMake to locate.
              EGL )

find_library( # Sets the name of the path variable.
              GLES-lib
              # Specifies the name of the NDK library that
              # you want CMake to locate.
              GLESv3 )

target_link_libraries(glwrapper PUBLIC ${EGL-lib} ${GLES-lib} libc++.a pthread)
