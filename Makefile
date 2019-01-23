GO_EASY_ON_ME=1

ARCHS = armv7 arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Hive
Hive_FILES = Tweak.xm
Hive_FRAMEWORKS = UIKit
Hive_CFLAGS = -fobjc-arc
Hive_LDFLAGS += -lCSColorPicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += hive
include $(THEOS_MAKE_PATH)/aggregate.mk
