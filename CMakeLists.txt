cmake_minimum_required(VERSION 3.26...4.3)

project(PlaneGCS VERSION 1.1.1 LANGUAGES CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

option(PLANEGCS_INSTALL "Generate install and package config rules" ${PROJECT_IS_TOP_LEVEL})

find_package(Eigen3 REQUIRED)
find_package(Boost REQUIRED CONFIG)
find_package(fmt REQUIRED)

# src/ is regenerated from upstream FreeCAD by update.sh, so file names can
# change on a sync; CONFIGURE_DEPENDS picks that up without a manual reconfigure.
file(GLOB source_files CONFIGURE_DEPENDS src/*.cpp src/Base/*.cpp)
add_library(planegcs ${source_files})
add_library(PlaneGCS::planegcs ALIAS planegcs)

target_compile_features(planegcs PUBLIC cxx_std_20)

set_target_properties(
    planegcs
    PROPERTIES
        VERSION ${PROJECT_VERSION}
        # Major.minor tracks the upstream FreeCAD release branch (see update.sh),
        # and FreeCAD doesn't keep the solver's API stable across minor
        # releases, so a minor bump may break ABI.
        SOVERSION ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        # SketcherGlobal.h makes SketcherExport dllexport only when
        # Sketcher_EXPORTS is defined (dllimport otherwise, on Windows).
        DEFINE_SYMBOL Sketcher_EXPORTS
)

# For a static library there is nothing to import, so blank the macro out for
# both this target and its consumers (SketcherGlobal.h guards its own
# definition with #ifndef SketcherExport).
get_target_property(planegcs_type planegcs TYPE)
if(planegcs_type STREQUAL "STATIC_LIBRARY")
    target_compile_definitions(planegcs PUBLIC SketcherExport=)
endif()

target_include_directories(
    planegcs
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/PlaneGCS>
)
# Eigen3::Eigen and fmt::fmt are public: GCS.h/SubSystem.h expose Eigen types
# directly, and Base/Console.h (the log/warning redirect hook) needs
# fmt/printf.h. Boost is only used for header-only Boost.Graph inside .cpp
# files, so it is wrapped in BUILD_LOCAL_INTERFACE: it never appears in the
# exported targets and consumers don't need Boost installed.
target_link_libraries(
    planegcs
    PUBLIC
        Eigen3::Eigen
        fmt::fmt
    PRIVATE
        $<BUILD_LOCAL_INTERFACE:Boost::headers>
)

if(PLANEGCS_INSTALL)
    install(
        TARGETS planegcs
        EXPORT PlaneGCSTargets
        ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    )
    install(
        DIRECTORY include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/PlaneGCS
        PATTERN boost_graph_adjacency_list.hpp EXCLUDE
    )

    install(
        EXPORT PlaneGCSTargets
        FILE PlaneGCSTargets.cmake
        NAMESPACE PlaneGCS::
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/PlaneGCS
    )

    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/PlaneGCSConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMinorVersion
    )
    configure_package_config_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/cmake/PlaneGCSConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/PlaneGCSConfig.cmake
        INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/PlaneGCS
    )
    install(
        FILES
            ${CMAKE_CURRENT_BINARY_DIR}/PlaneGCSConfig.cmake
            ${CMAKE_CURRENT_BINARY_DIR}/PlaneGCSConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/PlaneGCS
    )
endif()
