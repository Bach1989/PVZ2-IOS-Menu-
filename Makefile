TARGET := iphone:clang:latest:11.0
ARCHS := arm64 arm64e

# Jailbreak rootless (Dopamine, palera1n rootless...): bỏ dấu # ở dòng dưới
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PvZMenu
PvZMenu_FILES = Tweak.m
PvZMenu_CFLAGS = -fobjc-arc
PvZMenu_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
