include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = Hive
Hive_FILES = HVERootListController.m
Hive_INSTALL_PATH = /Library/PreferenceBundles
Hive_FRAMEWORKS = UIKit
Hive_PRIVATE_FRAMEWORKS = Preferences
Hive_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
Hive_LDFLAGS += -lCSColorPicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/Hive.plist$(ECHO_END)
