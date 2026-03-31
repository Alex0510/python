export THEOS_DEVICE_IP = 127.0.0.1
export THEOS_DEVICE_PORT = 22

ARCHS = arm64
TARGET = iphone:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = qinghook
qinghook_FILES = Tweak.xm
qinghook_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
