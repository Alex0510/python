export THEOS=/home/runner/theos
export SDKVERSION=15.0
export TARGET = iphone:clang:latest:11.0
export ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpeedCNVIPUnlocker

SpeedCNVIPUnlocker_FILES = Tweak.xm
SpeedCNVIPUnlocker_CFLAGS = -fobjc-arc
SpeedCNVIPUnlocker_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk