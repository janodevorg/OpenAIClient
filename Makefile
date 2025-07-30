PROJECT_NAME = OpenAIClient
MK_DIR = ./mk

# Check if mk directory exists
ifeq ($(wildcard $(MK_DIR)),)
    $(warning WARNING: mk directory not found. Please run 'git submodule update --init --recursive' to initialize the build tools)
endif

include $(MK_DIR)/package.mk