ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES = blued

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = blued
RemoveAdmsFields_FILES = Tweak.x
RemoveAdmsFields_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk