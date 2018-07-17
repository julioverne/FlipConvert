include theos/makefiles/common.mk

TWEAK_NAME = z_FlipConvert
z_FlipConvert_FILES = /mnt/d/codes/flipconvert/FlipConvert.xm
z_FlipConvert_FRAMEWORKS = CydiaSubstrate Foundation UIKit CoreGraphics QuartzCore CoreImage CoreFoundation
z_FlipConvert_PRIVATE_FRAMEWORKS = ControlCenterUIKit

z_FlipConvert_LDFLAGS = -Wl,-segalign,4000

export ARCHS = arm64
z_FlipConvert_ARCHS = arm64

include $(THEOS_MAKE_PATH)/tweak.mk
	
	
all::
	