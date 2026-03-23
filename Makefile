# Makefile
export THEOS=/home/runner/theos

ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = liebaovpnVIPUnlocker

liebaovpnVIPUnlocker_FILES = Tweak.xm
liebaovpnVIPUnlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
liebaovpnVIPUnlocker_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk