ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:7.0
INSTALL_TARGET_PROCESSES = Qing_ios

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FlashToNormal
FlashToNormal_FILES = Tweak.xm
FlashToNormal_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk