export THEOS=/opt/theos

TARGET = iphone:clang:latest:11.0
ARCHS = arm64 arm64e

# 注入到所有App
INSTALL_TARGET_PROCESSES = SpringBoard
# 或者指定特定App: INSTALL_TARGET_PROCESSES = WeChat

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppCleaner

# 添加所有源文件
AppCleaner_FILES = Tweak.xm AppCleanerPlugin.m
AppCleaner_FRAMEWORKS = UIKit WebKit Foundation Security
AppCleaner_CFLAGS = -fobjc-arc
AppCleaner_PRIVATE_FRAMEWORKS = 
AppCleaner_LIBRARIES = 

# 注入到所有进程
AppCleaner_FILTER = BUNDLE_IDENTIFIER=.*

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"