cmake_minimum_required(VERSION 3.16)

set(SUPPORTED_TARGETS esp32)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
set(EXTRA_COMPONENT_DIRS src)
project(openhaystack)
