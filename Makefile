export ARCHS = arm64 arm64e
export TARGET = iphone:clang:latest:15.0

INSTALL_TARGET_PROCESSES = budget

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = budgetPro

budgetPro_FILES = Tweak.xm
budgetPro_CFLAGS = -fobjc-arc
budgetPro_FRAMEWORKS = StoreKit Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk