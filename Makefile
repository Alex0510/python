INSTALL_TARGET_PROCESSES = blued
TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = blued
ZSLoginBypass_FILES = Tweak.xm
# 如果需要链接特定框架，可以在这里添加
ZSLoginBypass_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk