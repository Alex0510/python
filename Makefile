ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NewDeviceTweak

NewDeviceTweak_FILES = Tweak.xm NDManager.m NDFloatingView.m
NewDeviceTweak_FRAMEWORKS = UIKit Foundation Security
NewDeviceTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk