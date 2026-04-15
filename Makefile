TARGET := iphone:clang:latest
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AllCleanPro

AllCleanPro_FILES = Tweak.xm ACManager.m ACFloating.m
AllCleanPro_FRAMEWORKS = UIKit WebKit Security

include $(THEOS_MAKE_PATH)/tweak.mk