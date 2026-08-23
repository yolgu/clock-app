cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "auto_start_bridge.cpp"
  "flutter_window.cpp"
  "instance_coordinator.cpp"
  "local_state_file.cpp"
  "main.cpp"
  "utils.cpp"
  "windows_version.cpp"
  "window_placement.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

set(_clock_rhythm_dart_flavor "")
set(_clock_rhythm_generated_config
  "${FLUTTER_MANAGED_DIR}/ephemeral/generated_config.cmake")
if(EXISTS "${_clock_rhythm_generated_config}")
  file(READ "${_clock_rhythm_generated_config}" _clock_rhythm_flutter_config)
  string(FIND "${_clock_rhythm_flutter_config}"
    "Q0xPQ0tfUkhZVEhNX0ZMQVZPUj1iZXRh" _clock_rhythm_beta_define)
  string(FIND "${_clock_rhythm_flutter_config}"
    "Q0xPQ0tfUkhZVEhNX0ZMQVZPUj1wcm9kdWN0aW9u"
    _clock_rhythm_production_define)
  if(NOT _clock_rhythm_beta_define EQUAL -1 AND
     NOT _clock_rhythm_production_define EQUAL -1)
    message(FATAL_ERROR "Conflicting CLOCK_RHYTHM_FLAVOR Dart defines")
  elseif(NOT _clock_rhythm_beta_define EQUAL -1)
    set(_clock_rhythm_dart_flavor "beta")
  elseif(NOT _clock_rhythm_production_define EQUAL -1)
    set(_clock_rhythm_dart_flavor "production")
  endif()
endif()

set(_clock_rhythm_environment_flavor "")
if(DEFINED ENV{CLOCK_RHYTHM_WINDOWS_FLAVOR} AND
   NOT "$ENV{CLOCK_RHYTHM_WINDOWS_FLAVOR}" STREQUAL "")
  string(TOLOWER "$ENV{CLOCK_RHYTHM_WINDOWS_FLAVOR}"
    _clock_rhythm_environment_flavor)
endif()
if(NOT _clock_rhythm_environment_flavor STREQUAL "" AND
   NOT _clock_rhythm_dart_flavor STREQUAL "" AND
   NOT _clock_rhythm_environment_flavor STREQUAL _clock_rhythm_dart_flavor)
  message(FATAL_ERROR "Windows and Dart flavor inputs disagree")
endif()
if(NOT _clock_rhythm_environment_flavor STREQUAL "")
  set(_clock_rhythm_flavor "${_clock_rhythm_environment_flavor}")
elseif(NOT _clock_rhythm_dart_flavor STREQUAL "")
  set(_clock_rhythm_flavor "${_clock_rhythm_dart_flavor}")
else()
  set(_clock_rhythm_flavor "production")
endif()

if(_clock_rhythm_flavor STREQUAL "beta")
  set(_clock_rhythm_identity "dev.wndls.clockrhythm.beta")
  set(_clock_rhythm_display_name "Clock Rhythm Beta")
  set(_clock_rhythm_registration_name "Clock Rhythm Beta")
  set(_clock_rhythm_startup_task_id "ClockRhythmBetaStartup")
elseif(_clock_rhythm_flavor STREQUAL "production")
  set(_clock_rhythm_identity "dev.wndls.clockrhythm")
  set(_clock_rhythm_display_name "Clock Rhythm")
  set(_clock_rhythm_registration_name "Clock Rhythm")
  set(_clock_rhythm_startup_task_id "ClockRhythmStartup")
else()
  message(FATAL_ERROR
    "CLOCK_RHYTHM_WINDOWS_FLAVOR must be beta or production")
endif()

set(CLOCK_RHYTHM_WINDOWS_FLAVOR "${_clock_rhythm_flavor}" CACHE STRING
  "Clock Rhythm Windows flavor" FORCE)
set(CLOCK_RHYTHM_WINDOWS_IDENTITY "${_clock_rhythm_identity}" CACHE INTERNAL
  "Derived Windows identity" FORCE)
set(CLOCK_RHYTHM_DISPLAY_NAME "${_clock_rhythm_display_name}"
  CACHE INTERNAL "Derived Windows display name" FORCE)
set(CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME
  "${_clock_rhythm_registration_name}" CACHE INTERNAL
  "Derived HKCU Run registration" FORCE)
set(CLOCK_RHYTHM_STARTUP_TASK_ID "${_clock_rhythm_startup_task_id}"
  CACHE INTERNAL "Derived MSIX StartupTask ID" FORCE)
target_compile_definitions(${BINARY_NAME} PRIVATE
  "CLOCK_RHYTHM_WINDOWS_IDENTITY=\"${CLOCK_RHYTHM_WINDOWS_IDENTITY}\""
  "CLOCK_RHYTHM_DISPLAY_NAME=\"${CLOCK_RHYTHM_DISPLAY_NAME}\""
  "CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME=\"${CLOCK_RHYTHM_AUTOSTART_REGISTRATION_NAME}\""
  "CLOCK_RHYTHM_STARTUP_TASK_ID=\"${CLOCK_RHYTHM_STARTUP_TASK_ID}\"")

if(DEFINED ENV{CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START} AND
   "$ENV{CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START}" STREQUAL "1")
  target_compile_definitions(${BINARY_NAME} PRIVATE
    "CLOCK_RHYTHM_TEST_FORCE_VISIBLE_HIDDEN_START=1")
endif()

set_property(TARGET ${BINARY_NAME} PROPERTY
  VS_WINDOWS_TARGET_PLATFORM_MIN_VERSION "10.0.17763.0")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_link_libraries(${BINARY_NAME} PRIVATE
  "advapi32.lib" "shell32.lib" "windowsapp.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Focused native contract test. EXCLUDE_FROM_ALL keeps it out of application
# artifacts while allowing the lifecycle harness to build it explicitly.
add_executable(clock_rhythm_windows_native_tests EXCLUDE_FROM_ALL
  "${CMAKE_SOURCE_DIR}/../test/windows/windows_lifecycle_native_test.cpp"
  "auto_start_bridge.cpp"
  "local_state_file.cpp"
  "runner.exe.manifest"
  "windows_version.cpp"
  "window_placement.cpp"
)
apply_standard_settings(clock_rhythm_windows_native_tests)
target_compile_definitions(clock_rhythm_windows_native_tests PRIVATE "NOMINMAX")
target_include_directories(clock_rhythm_windows_native_tests PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(clock_rhythm_windows_native_tests PRIVATE
  "advapi32.lib" "shell32.lib" "windowsapp.lib")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)
