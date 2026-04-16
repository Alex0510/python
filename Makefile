
PACKAGE_NAME = AppCleaner
TARGET = iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppCleaner
AppCleaner_FILES = Tweak.x
AppCleaner_CFLAGS = -fobjc-arc
AppCleaner_FRAMEWORKS = UIKit Foundation QuartzCore Security

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"