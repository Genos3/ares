# ares CMake macOS compiler configuration module

include_guard(GLOBAL)

option(ENABLE_COMPILER_TRACE "Enable clang time-trace" OFF)
mark_as_advanced(ENABLE_COMPILER_TRACE)

option(
  ARES_BUILD_LOCAL
  "Allows the compiler to generate code optimized for the target machine; increases performance. Also disables certain entitlements and runtime options that interfere with debugging but are required for notarization and distribution."
  ON
)

include(ccache)
include(compiler_common)

# Enable selection between arm64 and x86_64 targets
if(NOT CMAKE_OSX_ARCHITECTURES)
  set(CMAKE_OSX_ARCHITECTURES ${CMAKE_SYSTEM_PROCESSOR} CACHE STRING "Build architectures for macOS" FORCE)
endif()
set_property(CACHE CMAKE_OSX_ARCHITECTURES PROPERTY STRINGS arm64 x86_64)

# Ensure recent enough Xcode and platform SDK
function(check_sdk_requirements)
  set(ares_macos_minimum_sdk 11.1) # Minimum tested SDK
  set(ares_macos_minimum_xcode 12.4) # Sync with SDK
  execute_process(
    COMMAND xcrun --sdk macosx --show-sdk-platform-version
    OUTPUT_VARIABLE ares_macos_current_sdk
    RESULT_VARIABLE result
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if(NOT result EQUAL 0)
    message(
      FATAL_ERROR
      "Failed to fetch macOS SDK version. "
      "Ensure that the macOS SDK is installed and that xcode-select points at the Xcode developer directory."
    )
  endif()
  message(DEBUG "macOS SDK version: ${ares_macos_current_sdk}")
  if(ares_macos_current_sdk VERSION_LESS ares_macos_minimum_sdk)
    message(
      FATAL_ERROR
      "Your macOS SDK version (${ares_macos_current_sdk}) is too low. "
      "The macOS ${ares_macos_minimum_sdk} SDK (Xcode ${ares_macos_minimum_xcode}) is required to build ares."
    )
  endif()
  if(XCODE)
    if(XCODE_VERSION VERSION_LESS ares_macos_minimum_xcode)
      message(
        FATAL_ERROR
        "Your Xcode version (${XCODE_VERSION}) is too low. Xcode ${ares_macos_minimum_xcode} is required to build ares."
      )
    endif()
  endif()
endfunction()

check_sdk_requirements()

# Enable dSYM generator for release builds
string(APPEND CMAKE_C_FLAGS_RELEASE " -g")
string(APPEND CMAKE_CXX_FLAGS_RELEASE " -g")
string(APPEND CMAKE_OBJC_FLAGS_RELEASE " -g")
string(APPEND CMAKE_OBJCXX_FLAGS_RELEASE " -g")

if(ARES_BUILD_LOCAL)
  add_compile_options($<$<NOT:$<CONFIG:Debug>>:-march=native>)
else()
  if(CMAKE_OSX_ARCHITECTURES MATCHES arm64)
    #
  else()
    add_compile_options($<$<NOT:$<CONFIG:Debug>>:-march=x86-64-v2>)
  endif()
endif()

if(ENABLE_COMPILER_TRACE)
  add_compile_options(-ftime-trace)
  add_link_options(LINKER:-print_statistics)
endif()

if(NOT XCODE)
  add_compile_options(
    "$<$<COMPILE_LANGUAGE:C>:${_ares_clang_c_options}>"
    "$<$<COMPILE_LANGUAGE:CXX>:${_ares_clang_cxx_options}>"
    -fwrapv
  )
endif()
