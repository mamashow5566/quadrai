cmake_minimum_required(VERSION 3.16)
project(quadra VERSION 1.3.0 LANGUAGES CXX)

# Options
option(PORTABLE_BUILD "Bundle all DLLs for portable distribution (Windows only)" OFF)
option(USE_STATIC_MSVC "Link MSVC runtime statically (/MT)" OFF)
option(ENABLE_APP_BUNDLE "Build as macOS application bundle" ${APPLE})

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Static MSVC runtime
if(USE_STATIC_MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/$<CONFIG>)

# Generate config.h from template
configure_file(
    ${CMAKE_SOURCE_DIR}/config.h.cmakein
    ${CMAKE_BINARY_DIR}/config.h
)

# Define HAVE_CONFIG_H for all targets
add_definitions(-DHAVE_CONFIG_H)

# Define DATAGAMESDIR
add_definitions(-DDATAGAMESDIR=\"${CMAKE_INSTALL_PREFIX}/share/games\")

# Platform-specific settings
if(WIN32)
    set(PLATFORM_LIBS ws2_32)
else()
    set(PLATFORM_LIBS)
    if(APPLE)
        add_definitions(-DENABLE_APP_BUNDLE)
    endif()
endif()

# Find dependencies
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
find_package(SDL2 REQUIRED)
find_package(ZLIB REQUIRED)
find_package(PNG REQUIRED)
find_package(Boost REQUIRED COMPONENTS system filesystem)

# Include directories
include_directories(${CMAKE_BINARY_DIR})
include_directories(${CMAKE_SOURCE_DIR}/source)
include_directories(${SDL2_INCLUDE_DIRS})
include_directories(${ZLIB_INCLUDE_DIRS})
include_directories(${PNG_INCLUDE_DIRS})
include_directories(${Boost_INCLUDE_DIRS})

# Source files
set(QUADRA_SOURCES
    source/attack.h
    source/bitmap.cc
    source/bitmap.h
    source/bloc.cc
    source/bloc.h
    source/buf.cc
    source/buf.h
    source/canvas.cc
    source/canvas.h
    source/cfgfile.cc
    source/cfgfile.h
    source/chat_text.cc
    source/chat_text.h
    source/clipable.cc
    source/clipable.h
    source/clock.cc
    source/clock.h
    source/color.cc
    source/color.h
    source/command.cc
    source/command.h
    source/crypt.cc
    source/crypt.h
    source/cursor.cc
    source/cursor.h
    source/dict.cc
    source/dict.h
    source/error.cc
    source/error.h
    source/fonts.cc
    source/fonts.h
    source/game.cc
    source/game.h
    source/game_menu.cc
    source/game_menu.h
    source/global.cc
    source/global.h
    source/highscores.cc
    source/highscores.h
    source/http_post.cc
    source/http_post.h
    source/http_request.cc
    source/http_request.h
    source/id.cc
    source/id.h
    source/image.h
    source/image_png.cc
    source/image_png.h
    source/input.cc
    source/input.h
    source/inter.cc
    source/inter.h
    source/listbox.cc
    source/listbox.h
    source/main.cc
    source/main.h
    source/menu.cc
    source/menu.h
    source/menu_base.cc
    source/menu_base.h
    source/menu_demo_central.cc
    source/menu_demo_central.h
    source/misc.cc
    source/misc.h
    source/multi_player.cc
    source/multi_player.h
    source/net.cc
    source/net.h
    source/net_buf.h
    source/net_call.h
    source/net_list.cc
    source/net_list.h
    source/net_server.cc
    source/net_server.h
    source/net_stuff.cc
    source/net_stuff.h
    source/nglog.cc
    source/nglog.h
    source/notify.cc
    source/notify.h
    source/overmind.cc
    source/overmind.h
    source/packet.cc
    source/packet.h
    source/packets.cc
    source/packets.h
    source/palette.cc
    source/palette.h
    source/pane.cc
    source/pane.h
    source/player.cc
    source/player.h
    source/qserv.cc
    source/qserv.h
    source/quadra.cc
    source/quadra.h
    source/random.cc
    source/random.h
    source/recording.cc
    source/recording.h
    source/res.cc
    source/res.h
    source/res_compress.cc
    source/res_compress.h
    source/res_name.cc
    source/res_name.h
    source/resfile.cc
    source/resfile.h
    source/resmanager.cc
    source/resmanager.h
    source/score.cc
    source/score.h
    source/sons.cc
    source/sons.h
    source/sound.cc
    source/sound.h
    source/sprite.cc
    source/sprite.h
    source/stats.cc
    source/stats.h
    source/stringtable.cc
    source/stringtable.h
    source/texte.h
    source/types.h
    source/unicode.cc
    source/unicode.h
    source/update.cc
    source/update.h
    source/url.cc
    source/url.h
    source/version.h
    source/video.cc
    source/video.h
    source/video_dumb.cc
    source/video_dumb.h
    source/zone.cc
    source/zone.h
    source/zone_list.cc
    source/zone_list.h
    source/zone_text_clock.cc
    source/zone_text_clock.h
)

# Build wadder tool
add_executable(wadder
    source/error.cc
    source/res.cc
    source/resfile.cc
    source/resmanager.cc
    source/stringtable.cc
    source/wadder.cc
)
target_link_libraries(wadder
    ${SDL2_LIBRARIES}
    ${ZLIB_LIBRARIES}
    ${PNG_LIBRARIES}
    ${Boost_LIBRARIES}
)
target_include_directories(wadder PRIVATE ${CMAKE_BINARY_DIR})

# Build quadra executable (WIN32=no console on Windows, MACOSX_BUNDLE handled separately)
if(WIN32)
    add_executable(quadra WIN32 ${QUADRA_SOURCES})
else()
    add_executable(quadra ${QUADRA_SOURCES})
endif()
target_link_libraries(quadra
    ${SDL2_LIBRARIES}
    ${ZLIB_LIBRARIES}
    ${PNG_LIBRARIES}
    ${Boost_LIBRARIES}
    ${PLATFORM_LIBS}
)
target_include_directories(quadra PRIVATE ${CMAKE_BINARY_DIR})

# macOS application bundle
if(ENABLE_APP_BUNDLE)
    set_target_properties(quadra PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.ludus.quadra"
        MACOSX_BUNDLE_BUNDLE_NAME "Quadra"
        MACOSX_BUNDLE_BUNDLE_VERSION "${PROJECT_VERSION}"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}"
    )
    set(MACOSX_BUNDLE_RES_DIR "${CMAKE_BINARY_DIR}/$<CONFIG>/quadra.app/Contents/Resources")
endif()

# Generate quadra.res using wadder
add_custom_command(
    OUTPUT ${CMAKE_BINARY_DIR}/quadra.res
    COMMAND $<TARGET_FILE:wadder> ${CMAKE_SOURCE_DIR}/ ${CMAKE_BINARY_DIR}/quadra.res ${CMAKE_SOURCE_DIR}/resources.txt
    DEPENDS wadder ${CMAKE_SOURCE_DIR}/resources.txt
    COMMENT "Generating quadra.res"
)

# Set preprocessor definition for DATAGAMESDIR
target_compile_definitions(quadra PRIVATE DATAGAMESDIR="\"${CMAKE_INSTALL_PREFIX}/share/games\"")

# Create config.h in binary directory if it doesn't exist
# file(WRITE ${CMAKE_BINARY_DIR}/config.h "#pragma once\n")

# Add quadra.res as a custom target to ensure it's built
add_custom_target(quadra_res ALL
    DEPENDS ${CMAKE_BINARY_DIR}/quadra.res
)

# Copy quadra.res to the runtime output directory
add_custom_command(TARGET quadra_res POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        ${CMAKE_BINARY_DIR}/quadra.res
        ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/quadra.res
)

# Install rules
install(TARGETS quadra
    RUNTIME DESTINATION bin
)

install(FILES ${CMAKE_BINARY_DIR}/quadra.res
    DESTINATION share/games
)
# ── Portable distribution bundling ──
if(WIN32 AND PORTABLE_BUILD)
    set(PORTABLE_DIR "${CMAKE_BINARY_DIR}/portable")

    # Locate the vcpkg binary directory
    if(DEFINED ENV{VCPKG_ROOT})
        set(VCPKG_INSTALLED_DIR "$ENV{VCPKG_ROOT}/installed")
    elseif(DEFINED VCPKG_INSTALLED_DIR)
        # Already set by vcpkg toolchain (internal variable, may not be available)
    elseif(CMAKE_TOOLCHAIN_FILE)
        cmake_path(GET CMAKE_TOOLCHAIN_FILE PARENT_PATH VCPKG_ROOT_DIR)
        cmake_path(GET VCPKG_ROOT_DIR PARENT_PATH VCPKG_ROOT_DIR)
        if(EXISTS "${VCPKG_ROOT_DIR}/installed")
            set(VCPKG_INSTALLED_DIR "${VCPKG_ROOT_DIR}/installed")
        endif()
    endif()

    if(NOT VCPKG_INSTALLED_DIR)
        # Fallback: search common vcpkg locations
        foreach(PFX "$ENV{USERPROFILE}" "C:/" "C:/dev")
            if(EXISTS "${PFX}/vcpkg/installed")
                set(VCPKG_INSTALLED_DIR "${PFX}/vcpkg/installed")
                break()
            endif()
        endforeach()
    endif()

    # Detect vcpkg target triplet
    if(NOT DEFINED VCPKG_TARGET_TRIPLET)
        file(GLOB TRIPLET_DIRS "${VCPKG_INSTALLED_DIR}/*")
        foreach(DIR ${TRIPLET_DIRS})
            if(IS_DIRECTORY "${DIR}" AND EXISTS "${DIR}/bin")
                get_filename_component(TRIPLET "${DIR}" NAME)
                if(TRIPLET MATCHES "^x64-windows")
                    set(VCPKG_TARGET_TRIPLET "${TRIPLET}")
                    break()
                endif()
            endif()
        endforeach()
    endif()
    set(VCPKG_BIN "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/bin")
    message(STATUS "Portable: using vcpkg triplet ${VCPKG_TARGET_TRIPLET}, bin: ${VCPKG_BIN}")

    # Create portable directory and copy exe + res
    add_custom_target(portable ALL
        COMMAND ${CMAKE_COMMAND} -E make_directory "${PORTABLE_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:quadra>" "${PORTABLE_DIR}/quadra.exe"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_BINARY_DIR}/quadra.res" "${PORTABLE_DIR}/quadra.res"
        COMMENT "Creating portable distribution..."
        DEPENDS quadra quadra_res
    )

    # Bundle vcpkg DLLs
    set(VCPKG_DLLS SDL2.dll z.dll libpng16.dll)
    foreach(DLL ${VCPKG_DLLS})
        if(EXISTS "${VCPKG_BIN}/${DLL}")
            add_custom_command(TARGET portable POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different
                    "${VCPKG_BIN}/${DLL}" "${PORTABLE_DIR}/"
                COMMENT "Bundling ${DLL}")
        endif()
    endforeach()

    # Boost DLLs (versioned names)
    file(GLOB BOOST_DLLS "${VCPKG_BIN}/boost_*-vc143-mt-x64-*.dll")
    foreach(DLL ${BOOST_DLLS})
        get_filename_component(DLL_NAME "${DLL}" NAME)
        add_custom_command(TARGET portable POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${DLL}" "${PORTABLE_DIR}/"
            COMMENT "Bundling ${DLL_NAME}")
    endforeach()

    # VC++ redist DLLs (local deployment)
    if(NOT USE_STATIC_MSVC)
        set(MSVC_REDIST_CRT)
        file(TO_CMAKE_PATH "$ENV{VCToolsRedistDir}" VCTOOLS_REDIST)
        if(VCTOOLS_REDIST)
            set(MSVC_REDIST_CRT "${VCTOOLS_REDIST}/x64/Microsoft.VC143.CRT")
        endif()
        if(NOT EXISTS "${MSVC_REDIST_CRT}")
            # Try to locate from VS installation
            foreach(VS_YEAR 2022 2019 2017)
                file(GLOB VS_EDITIONS
                    "C:/Program Files/Microsoft Visual Studio/${VS_YEAR}/*")
                foreach(VS_DIR ${VS_EDITIONS})
                    if(EXISTS "${VS_DIR}/VC/Redist/MSVC")
                        file(GLOB MSVC_VERSIONS LIST_DIRECTORIES true
                            "${VS_DIR}/VC/Redist/MSVC/*")
                        list(SORT MSVC_VERSIONS)
                        list(REVERSE MSVC_VERSIONS)
                        foreach(V ${MSVC_VERSIONS})
                            set(MSVC_REDIST_CRT "${V}/x64/Microsoft.VC143.CRT")
                            if(EXISTS "${MSVC_REDIST_CRT}")
                                break()
                            endif()
                        endforeach()
                        break()
                    endif()
                endforeach()
                if(EXISTS "${MSVC_REDIST_CRT}")
                    break()
                endif()
            endforeach()
        endif()
        if(EXISTS "${MSVC_REDIST_CRT}")
            file(GLOB MSVC_DLLS "${MSVC_REDIST_CRT}/*.dll")
            foreach(DLL ${MSVC_DLLS})
                get_filename_component(DLL_NAME "${DLL}" NAME)
                add_custom_command(TARGET portable POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${DLL}" "${PORTABLE_DIR}/"
                    COMMENT "Bundling MSVC: ${DLL_NAME}")
            endforeach()
        endif()
    endif()

    # Generate portable zip
    add_custom_command(TARGET portable POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E tar cf
            "${CMAKE_BINARY_DIR}/quadra-portable.zip"
            --format=zip --
            .
        WORKING_DIRECTORY "${PORTABLE_DIR}"
        COMMENT "Creating quadra-portable.zip")
endif()

# Simple test target
add_executable(simple_test simple_test.cc)
target_link_libraries(simple_test ${SDL2_LIBRARIES})
target_include_directories(simple_test PRIVATE ${SDL2_INCLUDE_DIRS})
