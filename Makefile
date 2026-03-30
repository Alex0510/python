ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = dokapro

dokapro_FILES = Tweak.xm
dokapro_FRAMEWORKS = UIKit Foundation


include $(THEOS_MAKE_PATH)/tweak.mk