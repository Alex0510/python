ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = URLBlockerPro

URLBlockerPro_FILES = Tweak.xm
URLBlockerPro_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk