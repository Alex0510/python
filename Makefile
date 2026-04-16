export THEOS=/opt/theos
PACKAGE_NAME = allclean
TARGET = iphone:clang:latest:11.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = allclean
allclean_FILES = Tweak.x
allclean_CFLAGS = -fobjc-arc
allclean_FRAMEWORKS = UIKit Foundation QuartzCore Security

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"