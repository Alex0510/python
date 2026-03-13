ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0        # 目标 iOS 版本设高一些，兼容 TrollStore 所需的最低版本
INSTALL_TARGET_PROCESSES = Python
THEOS_PACKAGE_SCHEME = rootless

ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
THEOS_PACKAGE_DIR = rootless
else ifeq ($(THEOS_PACKAGE_SCHEME),roothide)
THEOS_PACKAGE_DIR = roothide
else
THEOS_PACKAGE_DIR = rootful
endif

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = python

BluedAd_FILES = Tweak.xm
BluedAd_CFLAGS = -fobjc-arc
BluedAd_LDFLAGS = -lz

include $(THEOS_MAKE_PATH)/tweak.mk

clean::
	@echo -e "\033[31m==>\033[0m Cleaning packages…"
	@rm -rf .theos $(THEOS_PACKAGE_DIR)

after-package::
	@echo -e "\033[32m==>\033[0m Packaging complete."
	@echo -e "\033[34m==>\033[0m The .deb file is located at: $(THEOS_PACKAGE_DIR)/*.deb"
	@echo -e "\033[33m==>\033[0m For TrollStore installation, extract the .deb and copy the files manually:"
	@echo "  1. Unzip the .deb (ar -x *.deb; tar -xf data.tar.*)"
	@echo "  2. Copy BluedHook.dylib and BluedHook.plist to /var/jb/Library/MobileSubstrate/DynamicLibraries/"
	@echo "  3. Set permissions: chmod 644 *.dylib *.plist"
	@echo "  4. Restart the Blued app (force close and reopen)"
