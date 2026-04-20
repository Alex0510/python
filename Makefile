ARCHS = arm64 arm64e
TARGET = iphone:latest:13.0
INSTALL_TARGET_PROCESSES = TheosGUI

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SafeDispatchOnce
SafeDispatchOnce_FILES = Tweak.xm
SafeDispatchOnce_CFLAGS = -fobjc-arc
SafeDispatchOnce_LDFLAGS = -lsubstrate

include $(THEOS_MAKE_PATH)/tweak.mk