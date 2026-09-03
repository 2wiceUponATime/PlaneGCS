cmake_minimum_required(VERSION 3.30)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(PlaneGCS VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# CMake 3.30 defaults to CMP0167=NEW, which removes the bundled FindBoost.cmake
# module in favor of requiring Boost to ship its own BoostConfig.cmake. Many
# real-world Boost installs (e.g. Homebrew, several distro packages) don't
# provide one, so we opt back into the legacy module for broader
# compatibility. See PlaneGCSConfig.cmake.in for the same handling on the
# find_package(PlaneGCS) consumer side.
cmake_policy(SET CMP0167 OLD)

find_package(Eigen3 REQUIRED)
find_package(Boost REQUIRED COMPONENTS graph)
find_package(fmt REQUIRED)

file(GLOB source_files src/*.cpp src/Base/*.cpp)
add_library(planegcs ${source_files})
add_library(PlaneGCS::planegcs ALIAS planegcs)

target_include_directories(
    planegcs
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
# Eigen3::Eigen and fmt::fmt are public: GCS.h/SubSystem.h expose Eigen types
# directly, and Base/Console.h (the log/warning redirect hook) needs
# fmt/printf.h. Boost::graph is purely an implementation detail (only used
# inside .cpp files), so it stays PRIVATE. Unlike when these came from
# FetchContent, all three are now real find_package()-found IMPORTED
# targets, so they can be referenced directly here and via install(EXPORT)
# below without any BUILD_INTERFACE/INSTALL_INTERFACE workaround.
target_link_libraries(
    planegcs
    PUBLIC
        Eigen3::Eigen
        fmt::fmt
    PRIVATE
        Boost::graph
)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(
    TARGETS planegcs
    EXPORT PlaneGCSTargets
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

install(
    EXPORT PlaneGCSTargets
    FILE PlaneGCSTargets.cmake
    NAMESPACE PlaneGCS::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/PlaneGCS
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/PlaneGCSConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
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
