cmake_minimum_required(VERSION 3.21)

project(whisper-jni C CXX)

# ---- Set options ----

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(GGML_AVX                 "ggml: enable AVX"                ON )
option(GGML_AVX2                "ggml: enable AVX2"               ON )
option(GGML_FMA                 "ggml: enable FMA"                ON )
option(GGML_F16C                "ggml: enable F16c"               ON )
option(GGML_STATIC              "ggml: static link libraries"     OFF)
option(GGML_NATIVE              "ggml: enable -march=native flag" OFF)
option(BUILD_SHARED_LIBS        "whisper: build shared libs"      ON )
option(GGML_VULKAN              "ggml: enable Vulkan backend"     OFF)
option(GGML_BLAS                "ggml: BLAS CPU support"          OFF)

set(JAVA_AWT_LIBRARY NotNeeded)
set(JAVA_JVM_LIBRARY NotNeeded)

find_package(JNI REQUIRED)
if (JNI_FOUND)
    message (STATUS "JNI_INCLUDE_DIRS=${JNI_INCLUDE_DIRS}")
endif()

# Base C and CXX flags, start from current variables
set(EXTERNAL_C_FLAGS ${CMAKE_C_FLAGS})
set(EXTERNAL_CXX_FLAGS ${CMAKE_CXX_FLAGS})

if(MSVC)
  # Append /MD and the define to flags for MSVC
  string(APPEND EXTERNAL_C_FLAGS " /MD /D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
  string(APPEND EXTERNAL_CXX_FLAGS " /MD /D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
else()
  # For other compilers, just add the macro define
  string(APPEND EXTERNAL_C_FLAGS " -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
  string(APPEND EXTERNAL_CXX_FLAGS " -D_DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR")
endif()

if(MSVC)
  # Force compiler to use UTF-8 for IPA constants
  add_compile_options("$<$<C_COMPILER_ID:MSVC>:/utf-8>")
  add_compile_options("$<$<CXX_COMPILER_ID:MSVC>:/utf-8>")
elseif(NOT APPLE)
  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wl,-rpath,'$ORIGIN'")
  string(APPEND CMAKE_C_FLAGS " -Wall -Wextra")
  set(CMAKE_INSTALL_RPATH '$ORIGIN')
elseif(APPLE)
  set(CMAKE_INSTALL_RPATH "@loader_path")
endif()

# ---- Declare libraries ----

add_library(whisper-jni SHARED
  src/main/native/io_github_freshsupasulley_whisperjni_WhisperJNI.cpp
  # Needed
  src/main/native/whisper/examples/grammar-parser.cpp
)

# This is required to make whisper's release build work (particularly on Windows, unsure about other platforms)
target_compile_definitions(whisper-jni PRIVATE _DISABLE_CONSTEXPR_MUTEX_CONSTRUCTOR)

if(NOT DEFINED WHISPER_DIR)
  set(WHISPER_DIR "${CMAKE_CURRENT_BINARY_DIR}/w.cpp")
  set(WHISPER_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/w")
  include(ExternalProject)
  ExternalProject_Add(
    whisper-cpp
    PREFIX "${WHISPER_INSTALL_DIR}"
    URL "${CMAKE_CURRENT_LIST_DIR}/src/main/native/whisper"
    CMAKE_ARGS
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCMAKE_INSTALL_RPATH:STRING=${CMAKE_INSTALL_RPATH}
      -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS}
      -DCMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS}
      -DCMAKE_C_FLAGS=${EXTERNAL_C_FLAGS}
      -DCMAKE_CXX_FLAGS=${EXTERNAL_CXX_FLAGS}
      -DGGML_VULKAN=${GGML_VULKAN}
      -DGGML_BLAS=${GGML_BLAS}
      -DGGML_STATIC=${GGML_STATIC}
      -DGGML_NATIVE=${GGML_NATIVE}
      -DGGML_AVX=${GGML_AVX}
      -DGGML_AVX2=${GGML_AVX2}
      -DGGML_FMA=${GGML_FMA}
      -DGGML_F16C=${GGML_F16C}
      -DWHISPER_STANDALONE=1
      -DCMAKE_INSTALL_PREFIX:PATH=${WHISPER_DIR}
      -DCMAKE_OSX_ARCHITECTURES:STRING=${CMAKE_OSX_ARCHITECTURES}
      -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
  )
  add_dependencies(whisper-jni whisper-cpp)
endif()

if((NOT MSVC) AND (NOT APPLE))
  # Linux flags
  string(APPEND CMAKE_CXX_FLAGS " -Wall -Wextra -Wl,-rpath,'$ORIGIN'")
  string(APPEND CMAKE_C_FLAGS " -Wall -Wextra")
endif()

if(GGML_VULKAN)
  message(STATUS "GGML_VULKAN is enabled")
  message(STATUS "Vulkan SDK path: $ENV{VULKAN_SDK}")
  
  # Find the Vulkan package
  find_package(Vulkan REQUIRED)
  
  # Check that Vulkan was found
  if(Vulkan_FOUND)
    message(STATUS "Found Vulkan SDK at: ${Vulkan_INCLUDE_DIRS}")
    message(STATUS "Found Vulkan library: ${Vulkan_LIBRARIES}")

    # Link Vulkan to your target
    target_link_libraries(whisper-jni PRIVATE whisper ggml ggml-base ggml-cpu Vulkan::Vulkan)

    # Optionally include Vulkan directories if needed
    # ... is this required? probably
    target_include_directories(whisper-jni PRIVATE ${Vulkan_INCLUDE_DIRS})
  else()
    message(FATAL_ERROR "Vulkan SDK not found. Please ensure it is installed correctly.")
  endif()
else()
	target_link_libraries(whisper-jni whisper ggml ggml-base ggml-cpu)
endif()

target_link_directories(whisper-jni PUBLIC
  ${WHISPER_DIR}/lib
  ${WHISPER_DIR}/lib/static
  ${WHISPER_DIR}/build/ggml/src/${CMAKE_BUILD_TYPE}
)

target_include_directories(whisper-jni PUBLIC
  ${JNI_INCLUDE_DIRS}
  src/main/native
  ${WHISPER_DIR}/include
  # For grammar-parser.h. We include this in our cpp code
  ${WHISPER_INSTALL_DIR}/src/whisper-cpp/examples
)

# ---- Declare install targets ----

install(
  TARGETS whisper-jni
  DESTINATION ${CMAKE_INSTALL_PREFIX}
)

install(
  DIRECTORY ${WHISPER_DIR}/lib/
  DESTINATION ${CMAKE_INSTALL_PREFIX}
  USE_SOURCE_PERMISSIONS
  FILES_MATCHING
  PATTERN "*.so.*"
  PATTERN "*.so"
  PATTERN "*.dylib"
)

install(
  DIRECTORY ${WHISPER_DIR}/bin/
  DESTINATION ${CMAKE_INSTALL_PREFIX}
  USE_SOURCE_PERMISSIONS
  FILES_MATCHING
  PATTERN "*.dll"
)
