# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.16

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/Barbell/LC

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/Barbell/LC/build

# Include any dependencies generated for this target.
include src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/depend.make

# Include the progress variables for this target.
include src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/progress.make

# Include the compile flags for this target's objects.
include src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/flags.make

src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.o: src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/flags.make
src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.o: ../src/test/application_clients/nginx_client_libevent.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/Barbell/LC/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.o"
	cd /home/Barbell/LC/build/src/test/application_clients && /usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.o -c /home/Barbell/LC/src/test/application_clients/nginx_client_libevent.cpp

src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.i"
	cd /home/Barbell/LC/build/src/test/application_clients && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/Barbell/LC/src/test/application_clients/nginx_client_libevent.cpp > CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.i

src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.s"
	cd /home/Barbell/LC/build/src/test/application_clients && /usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/Barbell/LC/src/test/application_clients/nginx_client_libevent.cpp -o CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.s

# Object files for target nginx_client_libevent
nginx_client_libevent_OBJECTS = \
"CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.o"

# External object files for target nginx_client_libevent
nginx_client_libevent_EXTERNAL_OBJECTS =

src/test/application_clients/nginx_client_libevent: src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/nginx_client_libevent.cpp.o
src/test/application_clients/nginx_client_libevent: src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/build.make
src/test/application_clients/nginx_client_libevent: src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/Barbell/LC/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable nginx_client_libevent"
	cd /home/Barbell/LC/build/src/test/application_clients && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/nginx_client_libevent.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/build: src/test/application_clients/nginx_client_libevent

.PHONY : src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/build

src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/clean:
	cd /home/Barbell/LC/build/src/test/application_clients && $(CMAKE_COMMAND) -P CMakeFiles/nginx_client_libevent.dir/cmake_clean.cmake
.PHONY : src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/clean

src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/depend:
	cd /home/Barbell/LC/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/Barbell/LC /home/Barbell/LC/src/test/application_clients /home/Barbell/LC/build /home/Barbell/LC/build/src/test/application_clients /home/Barbell/LC/build/src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : src/test/application_clients/CMakeFiles/nginx_client_libevent.dir/depend

