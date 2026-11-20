# Build with the MSYS2 UCRT64 toolchain (run from a UCRT64 shell).
CXX      ?= g++
BUILD    := build
TARGET   := $(BUILD)/app.exe

CONFIG   ?= debug
CXXSTD   ?= c++26

# The Vulkan SDK installer sets VULKAN_SDK. Use forward slashes so GCC and
# the UCRT64 shell both accept the path, including when it contains spaces
VULKAN_SDK ?= $(VK_SDK_PATH)
ifeq ($(strip $(VULKAN_SDK)),)
$(error Set VULKAN_SDK to the Vulkan SDK installation directory)
endif

VULKAN_ROOT    := /$(patsubst /%,%,$(shell cygpath -u "$(VULKAN_SDK)"))
VULKAN_INCLUDE := $(VULKAN_ROOT)/Include
VULKAN_MODULE  := $(VULKAN_INCLUDE)/vulkan/vulkan.cppm

SOURCES := src/main.cpp
OBJECTS := $(patsubst src/%.cpp,$(BUILD)/%.o,$(SOURCES))

# External libraries
MODULE_OBJECTS := $(BUILD)/std.o $(BUILD)/vulkan.o

CPPFLAGS      := -isystem "$(VULKAN_INCLUDE)"
MODULE_FLAGS  := -std=$(CXXSTD) -fmodules -fconcepts -fcontracts
BASE_CXXFLAGS := $(MODULE_FLAGS) -Wall -Wextra -Wpedantic

ifeq ($(CONFIG),release)
  CXXFLAGS := $(BASE_CXXFLAGS) -O2 -DNDEBUG
else
  CXXFLAGS := $(BASE_CXXFLAGS) -O0 -g3
endif

# Resolve the MinGW import library from the UCRT64 toolchain's normal library
# paths (the SDK's .lib is the MSVC import library)
LDLIBS := -lvulkan-1
# GCC 16's MinGW modules emit some header-defined entities in both the module
# object and its importer.  Keep the module object first so its definitions
# satisfy the importer, GNU ld then ignores the duplicate copies
LDFLAGS += -Wl,--allow-multiple-definition

.PHONY: all clean
all: $(TARGET)

$(BUILD):
	mkdir -p "$@"

# GCC's standard library module interface ships as bits/std.cc.  Keep its
# module cache in the build directory, alongside the other BMIs
$(BUILD)/std.o: | $(BUILD)
	cd "$(BUILD)" && $(CXX) $(MODULE_FLAGS) -fsearch-include-path -c bits/std.cc -o std.o

# Vulkan-Hpp declares the exported named module `vulkan` in vulkan.cppm
$(BUILD)/vulkan.o: $(BUILD)/std.o
	cd "$(BUILD)" && $(CXX) $(CPPFLAGS) $(MODULE_FLAGS) -fsearch-include-path -c "$(VULKAN_MODULE)" -o vulkan.o

$(BUILD)/%.o: src/%.cpp $(BUILD)/std.o $(BUILD)/vulkan.o
	cd "$(BUILD)" && $(CXX) $(CPPFLAGS) $(CXXFLAGS) -I../include -c "$(abspath $<)" -o "$(@F)"

$(TARGET): $(MODULE_OBJECTS) $(OBJECTS)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o "$@" $^ $(LDLIBS)

clean:
	rm -rf "$(BUILD)"
