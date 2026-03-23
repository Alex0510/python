ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FomzPro

FomzPro_FILES = Tweak.xm
FomzPro_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk