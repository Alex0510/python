export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES = picsewPro

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = picsewPro

picsewPro_FILES = Tweak.xm
picsewPro_CFLAGS = -fobjc-arc
picsewPro_FRAMEWORKS = StoreKit

include $(THEOS_MAKE_PATH)/tweak.mk