# Makefile for kugou

TARGET = iphone:clang:latest
ARCHS = arm64

# 插件名称
TWEAK_NAME = kugou

# 源文件
kugou_FILES = Tweak.xm

# 链接标志
kugou_LDFLAGS = -fuse-ld=lld

# 框架
kugou_FRAMEWORKS = UIKit Foundation

# 包含 Theos 默认设置
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk