ARCHS = arm64 arm64e
TARGET = iphone:clang::13.5
SYSROOT = $(THEOS)/sdks/iPhoneOS13.5.sdk
PREFIX = $(THEOS)/toolchain/Xcode.xctoolchain/usr/bin/

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Puck
$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = UIKit
$(TWEAK_NAME)_EXTRA_FRAMEWORKS  = Cephei

include $(THEOS_MAKE_PATH)/tweak.mk
