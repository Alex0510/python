# Makefile for PythonIDEFix

TARGET = iphone:clang:latest
ARCHS = arm64

# 插件名称（会生成 .dylib 和 .plist）
TWEAK_NAME = kugou

# 源文件
PythonIDEFix_FILES = Tweak.xm

# 链接标志（可选）
PythonIDEFix_LDFLAGS = -fuse-ld=lld

# 必须包含的框架（如果有需要）
# PythonIDEFix_FRAMEWORKS = UIKit Foundation

# 包含 Theos 默认设置
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk