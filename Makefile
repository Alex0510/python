# Makefile
export THEOS=/opt/theos
export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:13.0

INSTALL_TARGET_PROCESSES = Fomz

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FomzPro

FomzPro_FILES = Tweak.xm
FomzPro_CFLAGS = -fobjc-arc
FomzPro_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk