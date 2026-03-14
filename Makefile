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

# 忽略未使用的变量/函数警告，以及废弃API警告
kugou_CFLAGS = -Wno-error=unused-variable -Wno-error=unused-function -Wno-error=deprecated-declarations

# 包含 Theos 默认设置
include $(THEOS)/makefiles/common.mk
include $(THEOS)/makefiles/tweak.mk