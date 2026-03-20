# 指定目标进程（安装后自动重启该应用）
INSTALL_TARGET_PROCESSES = ioszhushou

# 目标 SDK 版本和编译器
TARGET := iphone:clang:latest:14.0

# 支持的架构
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

# Tweak 名称（必须与文件夹名一致）
TWEAK_NAME = ioszhushou

# 源文件列表（使用 TWEAK_NAME 作为前缀）
ioszhushou_FILES = Tweak.xm

# 需要链接的框架
ioszhushou_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk