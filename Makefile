# 自动检测THEOS路径
ifndef THEOS
	THEOS = $(shell test -d /opt/theos && echo "/opt/theos" || echo "$(HOME)/theos")
endif

# 设置架构
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:11.0

# 使用环境变量或默认值
INSTALL_TARGET_PROCESSES = SpringBoard

# 包含Theos的makefiles
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppCleaner

# 源文件
AppCleaner_FILES = Tweak.xm AppCleanerPlugin.m
AppCleaner_FRAMEWORKS = UIKit WebKit Foundation Security
AppCleaner_CFLAGS = -fobjc-arc -O2
AppCleaner_PRIVATE_FRAMEWORKS = 
AppCleaner_LIBRARIES = 

# 注入到所有App
AppCleaner_FILTER = BUNDLE_IDENTIFIER=.*

# 包含tweak的makefile
include $(THEOS)/makefiles/tweak.mk

# 打包后处理
after-package::
	@echo "Package built successfully"

# 安装后处理
after-install::
	install.exec "killall -9 SpringBoard" || true