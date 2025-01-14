cmake_minimum_required(VERSION 3.14)

project(
    Barbell
    VERSION 1.0
    DESCRIPTION
    "Barbell is a open-loop load generator for various latency critical applications"
    LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Require at least gcc/g++ 4.8.5) CMAKE_CXX_COMPILER_VERSION OR
if (CMAKE_C_COMPILER_VERSION VERSION_LESS 7.3 OR CMAKE_CXX_COMPILER_VERSION
    VERSION_LESS 7.3)
  message(
      FATAL_ERROR "gcc and g++ version => 7.3 is required for building project!")
endif ()

# Find Packages and Modules
#list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include(cmake/hdr.cmake)
#include(cmake/gflag.cmake)
#include(cmake/glog.cmake)
#include(cmake/FindGlog.cmake)
#find_package(Glog REQUIRED)
#include_directories(BEFORE ${GLOG_INCLUDE_DIRS})

find_package(Lua REQUIRED)
find_package(Boost REQUIRED COMPONENTS headers program_options)
find_package(Threads REQUIRED)
find_package(OpenSSL REQUIRED)
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

include_directories(${PROJECT_SOURCE_DIR}/dependency)

add_subdirectory(src)
