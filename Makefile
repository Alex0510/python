# Makefile
export THEOS=/home/runner/theos
export ARCHS = arm64
export TARGET = iphone:clang:latest:13.0

TWEAK_NAME = FomzPro

FomzPro_FILES = Tweak.xm
FomzPro_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-objc-root-class
FomzPro_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk