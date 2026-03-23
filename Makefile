export THEOS=/opt/theos
export SDKVERSION=15.0

INSTALL_TARGET_PROCESSES = SpeedCN

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = SpeedCNVIPUnlocker

SpeedCNVIPUnlocker_FILES = Tweak.xm
SpeedCNVIPUnlocker_CFLAGS = -fobjc-arc
SpeedCNVIPUnlocker_FRAMEWORKS = UIKit Foundation
SpeedCNVIPUnlocker_PRIVATE_FRAMEWORKS = 

include $(THEOS_MAKE_PATH)/tweak.mk