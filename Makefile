# Makefile for kugou

TARGET = iphone:clang:latest
ARCHS = arm64

# 插件名称（会生成 .dylib 和 .plist）
TWEAK_NAME = kugou

# 源文件（使用 TWEAK_NAME 作为前缀）
kugou_FILES = Tweak.xm

# 链接标志（可选）
kugou_LDFLAGS = -fuse-ld=lld

# 必须包含的框架（如果有需要）
# kugou_FRAMEWORKS = UIKit Foundation

# 包含 Theos 默认设置
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk