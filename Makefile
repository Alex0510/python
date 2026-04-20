export THEOS ?= $(HOME)/theos
export THEOS_MAKE_PATH = $(THEOS)/makefiles

TWEAK_NAME = TrollFoolsAdRemover
# 使用 .x 扩展名（不经过 Logos 预处理）
TrollFoolsAdRemover_FILES = Tweak.xm fishhook.c
TrollFoolsAdRemover_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/tweak.mk
