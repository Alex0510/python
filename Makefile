ARCHS = arm64
TARGET = iphone:clang:latest:15.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = EgernProUnlock
EgernProUnlock_FILES = Tweak.xm
EgernProUnlock_CFLAGS = -fobjc-arc
EgernProUnlock_FRAMEWORKS = UIKit Foundation StoreKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Egern"