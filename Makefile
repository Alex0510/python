ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = XiaoXiaoLeHack

XiaoXiaoLeHack_FILES = Tweak.xm
XiaoXiaoLeHack_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk