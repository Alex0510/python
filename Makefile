THEOS_DEVICE_IP = localhost
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AddonsPro
VIPUnlocker_FILES = Tweak.xm
VIPUnlocker_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk