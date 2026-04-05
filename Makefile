export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = 暴雪VPN

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = unlockvip
unlockvip_FILES = Tweak.xm
unlockvip_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk