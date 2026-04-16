

TARGET = iphone:clang:latest:11.0
ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SandboxCleaner

SandboxCleaner_FILES = Tweak.xm SandboxCleanerPlugin.m
SandboxCleaner_FRAMEWORKS = UIKit WebKit Foundation Security
SandboxCleaner_CFLAGS = -fobjc-arc
SandboxCleaner_PRIVATE_FRAMEWORKS = 
SandboxCleaner_LIBRARIES = 

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"