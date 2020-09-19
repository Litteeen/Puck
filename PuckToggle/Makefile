ARCHS = arm64 arm64e
TARGET = iphone:clang::13.5

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = PuckToggle
$(BUNDLE_NAME)_BUNDLE_EXTENSION = bundle
$(BUNDLE_NAME)_FILES = PuckToggle.m
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = ControlCenterUIKit
$(BUNDLE_NAME)_INSTALL_PATH = /Library/ControlCenter/Bundles/

include $(THEOS_MAKE_PATH)/bundle.mk
