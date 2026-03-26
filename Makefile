ARCHS = arm64
TARGET = iphone:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AdBlockerPro
AdBlockerPro_FILES = Tweak.xm
AdBlockerPro_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk