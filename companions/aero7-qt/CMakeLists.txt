cmake_minimum_required(VERSION 3.20)

project(Aero7Qt VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

find_package(Qt6 6.6 REQUIRED COMPONENTS Core Gui Widgets)

add_library(Aero7Qt INTERFACE)
add_library(Aero7Qt::Aero7Qt ALIAS Aero7Qt)

target_compile_features(Aero7Qt INTERFACE cxx_std_17)
target_include_directories(Aero7Qt INTERFACE
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_link_libraries(Aero7Qt INTERFACE Qt6::Core Qt6::Gui Qt6::Widgets)

install(TARGETS Aero7Qt EXPORT Aero7QtTargets)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT Aero7QtTargets
    FILE Aero7QtTargets.cmake
    NAMESPACE Aero7Qt::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Aero7Qt
)

configure_package_config_file(
    cmake/Aero7QtConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/Aero7QtConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Aero7Qt
)
write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/Aero7QtConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)
install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/Aero7QtConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/Aero7QtConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/Aero7Qt
)

include(CTest)
if(BUILD_TESTING)
    add_executable(aero7qt-smoke tests/smoke.cpp)
    target_link_libraries(aero7qt-smoke PRIVATE Aero7Qt::Aero7Qt)
    add_test(NAME aero7qt-smoke COMMAND aero7qt-smoke)
    set_tests_properties(aero7qt-smoke PROPERTIES
        ENVIRONMENT "QT_QPA_PLATFORM=offscreen"
    )
endif()
