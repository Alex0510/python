# 在Makefile中
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = liebaovpnVIPUnlocker

liebaovpnVIPUnlocker_FILES = Tweak.x
liebaovpnVIPUnlocker_CFLAGS = -fobjc-arc
liebaovpnVIPUnlocker_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk