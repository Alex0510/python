export THEOS=/home/runner/theos
export SDKVERSION=14.5
export TARGET = iphone:clang:latest:11.0
export ARCHS = arm64

export ADDITIONAL_CFLAGS = -Wno-deprecated-declarations -Wno-deprecated

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpeedCNVIPUnlocker

SpeedCNVIPUnlocker_FILES = Tweak.xm
SpeedCNVIPUnlocker_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-deprecated -Wno-implicit-const-int-float-conversion
SpeedCNVIPUnlocker_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk