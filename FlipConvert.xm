#import <dlfcn.h>
#import <objc/runtime.h>
#import <substrate.h>
#import "FlipConvert.h"

#define NSLog(...)

NSMutableDictionary* allocates_forBunbdle()
{
	static __strong NSMutableDictionary* intanceDic;
	if(!intanceDic) {
		intanceDic = [[NSMutableDictionary alloc] init];
	}
	return intanceDic;
}

static void setValueWithId(NSString* identifier, NSString* key, id value)
{
	NSMutableDictionary* dicIden = [allocates_forBunbdle()[identifier]?:@{} mutableCopy];
	dicIden[key] = value;
	allocates_forBunbdle()[identifier] = dicIden;
}

static id getValueWithId(NSString* identifier, NSString* key)
{
	NSDictionary* dicKey = allocates_forBunbdle()[identifier];
	if(dicKey) {
		return dicKey[key];
	}
	return nil;
}

@interface UIImage ()
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

static CGFloat AspectScaleFit(CGSize sourceSize, CGRect destRect)
{
    CGSize destSize = destRect.size;
    CGFloat scaleW = destSize.width / sourceSize.width;
    CGFloat scaleH = destSize.height / sourceSize.height;
    return fmin(scaleW, scaleH);
}
static CGRect RectAroundCenter(CGPoint center, CGSize size)
{
    CGFloat halfWidth = size.width / 2.0f;
    CGFloat halfHeight = size.height / 2.0f;
    return CGRectMake(center.x - halfWidth, center.y - halfHeight, size.width, size.height);
}
static CGRect RectByFittingRect(CGRect sourceRect, CGRect destinationRect)
{
    CGFloat aspect = AspectScaleFit(sourceRect.size, destinationRect);
    CGSize targetSize = CGSizeMake(sourceRect.size.width * aspect, sourceRect.size.height * aspect);
    CGPoint center = CGPointMake(CGRectGetMidX(destinationRect), CGRectGetMidY(destinationRect));
    return RectAroundCenter(center, targetSize);
}
static void DrawPDFPageInRect(CGPDFPageRef pageRef, CGRect destinationRect)
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if(context == NULL) {
		return;
    }
    CGContextSaveGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
    transform = CGAffineTransformTranslate(transform, 0.0f, -image.size.height);
    CGContextConcatCTM(context, transform);
    CGRect d = CGRectApplyAffineTransform(destinationRect, transform);
    CGRect pageRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    CGFloat drawingAspect = AspectScaleFit(pageRect.size, d);
    CGRect drawingRect = RectByFittingRect(pageRect, d);
    CGContextTranslateCTM(context, drawingRect.origin.x, drawingRect.origin.y);
    CGContextScaleCTM(context, drawingAspect, drawingAspect);
    CGContextDrawPDFPage(context, pageRef);
    CGContextRestoreGState(context);
}
static UIImage *ImageFromPDFFileFlipConvert(NSString *pdfPath, CGSize targetSize, BOOL transparent)
{
    CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((CFURLRef)[NSURL fileURLWithPath:pdfPath]);
    if (pdfRef == NULL) {
		return nil;
    }
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0);
	if(!transparent) {
		[[UIColor lightGrayColor] setFill];
		UIRectFill(CGRectMake(0, 0, targetSize.width, targetSize.height));
	}
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdfRef, 1);
    DrawPDFPageInRect(pageRef, (CGRect){.size = targetSize});
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGPDFDocumentRelease(pdfRef);
    return image;
}


@implementation FlipConvertLongPressGestureRecognizer
@end

@implementation FlipConvert_PlaceHolder
@synthesize flipConvert_id;
- (BOOL)isSelected
{
	return ([[%c(FSSwitchPanel) sharedPanel] stateForSwitchIdentifier:flipConvert_id]==FSSwitchStateOn);
}
- (UIColor *)selectedColor
{
	return [[%c(FSSwitchPanel) sharedPanel] primaryColorForSwitchIdentifier:flipConvert_id]?:[UIColor lightGrayColor];
}
- (void)setSelected:(BOOL)selected
{
	[[%c(FSSwitchPanel) sharedPanel] setState:(FSSwitchState)selected forSwitchIdentifier:flipConvert_id];
	//[[%c(FSSwitchPanel) sharedPanel] applyActionForSwitchIdentifier:flipConvert_id];
	[super refreshState];
}
- (void)longPress:(FlipConvertLongPressGestureRecognizer *)recognizer
{
	if(recognizer.state == UIGestureRecognizerStateBegan) {
		if([[%c(FSSwitchPanel) sharedPanel] hasAlternateActionForSwitchIdentifier:flipConvert_id]) {
			[[%c(FSSwitchPanel) sharedPanel] applyAlternateActionForSwitchIdentifier:flipConvert_id];
			[super refreshState];
		}		
	}
}
-(UIImage *)iconGlyph
{
	UIViewController* selfViewCon = [self respondsToSelector:@selector(contentViewController)]?self.contentViewController:nil;
	if(selfViewCon) {
		FlipConvertLongPressGestureRecognizer* longTap = [[FlipConvertLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
		[longTap setNumberOfTapsRequired:0];
		[longTap setMinimumPressDuration:0.5f];
		[longTap setDelegate:self];
		for(UIGestureRecognizer *recognizer in selfViewCon.view.gestureRecognizers) {
			if(recognizer&&[recognizer isKindOfClass:%c(FlipConvertLongPressGestureRecognizer)]) {
				[selfViewCon.view removeGestureRecognizer:recognizer];
			}
		}
		[selfViewCon.view addGestureRecognizer:longTap];		
	}
	return [UIImage imageNamed:@"Icon-off" inBundle:[NSBundle bundleWithPath:getValueWithId(flipConvert_id, @"BundlePathRep")]];
}
-(UIImage *)selectedIconGlyph
{
	return [UIImage imageNamed:@"Icon-on" inBundle:[NSBundle bundleWithPath:getValueWithId(flipConvert_id, @"BundlePathRep")]];
}
@end


id initMethodIMP(id self, SEL _cmd)
{
	objc_super superInit = {self, [self superclass]};
	id initSuper = nil;
	NSString* classSt = [NSString stringWithFormat:@"%s", class_getName([self class])];
	for(NSString* idNow in [allocates_forBunbdle() allKeys]) {
		NSString* repSt = getValueWithId(idNow, @"NSPrincipalClassRep");
		if(repSt && [repSt isEqualToString:classSt]) {
			initSuper = getValueWithId(idNow, @"ClassRepAlloc");
			if(!initSuper) {
				initSuper = objc_msgSendSuper(&superInit, _cmd); 
			}
			setValueWithId(idNow, @"ClassRepAlloc", initSuper);
			((FlipConvert_PlaceHolder*)initSuper).flipConvert_id = idNow;
			break;
		}
	}
	if(!initSuper) {
		initSuper = objc_msgSendSuper(&superInit, _cmd);
	}
	return initSuper;
}

static void alloc_class_with_Name(const char * nameClass)
{
	Class newClass = objc_allocateClassPair([FlipConvert_PlaceHolder class], nameClass, 0);
	class_addMethod(newClass, @selector(init), (IMP)initMethodIMP, "@");
	objc_registerClassPair(newClass);
}

static NSString* getPortedPathFromBundlePath(NSString* bundlePath)
{
	return [@"/Library/ControlCenter/Bundles/" stringByAppendingPathComponent:[[[bundlePath lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:@"_FlipConvert.bundle"]];
}

static void allocForSwitchBundlePath(NSString* bundlePath)
{
	NSDictionary* infoPlist = [[NSDictionary alloc] initWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"Info.plist"]]?:@{};
	
	NSString* identifier = infoPlist[@"CFBundleIdentifier"];
	
	NSString* executable = infoPlist[@"CFBundleExecutable"]?:infoPlist[@"CFBundleDisplayName"]?:@"executable";
	NSString* principal_class = infoPlist[@"NSPrincipalClass"];
	
	[[NSBundle bundleWithPath:bundlePath] load];
	
	NSString* classRep = [NSString stringWithFormat:@"%@_%@", principal_class?:identifier, @"FlipConvert"];
	setValueWithId(identifier, @"NSPrincipalClassRep", classRep);
	setValueWithId(identifier, @"CFBundleExecutable", executable);
	setValueWithId(identifier, @"BundlePath", bundlePath);
	setValueWithId(identifier, @"BundlePathRep", getPortedPathFromBundlePath(bundlePath));
	
	alloc_class_with_Name(classRep.UTF8String);
}


NSMutableArray* bundlePathToMakeImage()
{
	static __strong NSMutableArray* intanceArr;
	if(!intanceArr) {
		intanceArr = [[NSMutableArray alloc] init];
	}
	return intanceArr;
}


static void bundlePathMakeImageNow()
{
	BOOL needRespring = NO;
	for(NSString* bundlePath in bundlePathToMakeImage()) {
		NSString* portPath = getPortedPathFromBundlePath(bundlePath);
		if(access([portPath stringByAppendingPathComponent:@"Icon-on@2x.png"].UTF8String, F_OK) != 0) {
			NSString* glyphPDFOn = nil;
			if(access([bundlePath stringByAppendingPathComponent:@"glyph-modern-on.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOn = [bundlePath stringByAppendingPathComponent:@"glyph-modern-on.pdf"];
			} else if(access([bundlePath stringByAppendingPathComponent:@"glyph-modern.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOn = [bundlePath stringByAppendingPathComponent:@"glyph-modern.pdf"];
			} else if(access([bundlePath stringByAppendingPathComponent:@"glyph-on.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOn = [bundlePath stringByAppendingPathComponent:@"glyph-on.pdf"];
			} else if(access([bundlePath stringByAppendingPathComponent:@"glyph.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOn = [bundlePath stringByAppendingPathComponent:@"glyph.pdf"];
			}
			if(glyphPDFOn) {
				NSData* size_48x = UIImagePNGRepresentation(ImageFromPDFFileFlipConvert(glyphPDFOn, CGSizeMake(32, 32), YES)); // 48
				NSData* size_72x = UIImagePNGRepresentation(ImageFromPDFFileFlipConvert(glyphPDFOn, CGSizeMake(40, 40), YES)); // 72
				
				[size_48x writeToFile:[portPath stringByAppendingPathComponent:@"Icon-on@2x.png"] atomically:YES];
				[size_72x writeToFile:[portPath stringByAppendingPathComponent:@"Icon-on@3x.png"] atomically:YES];
				
				NSData* _size_48x = UIImagePNGRepresentation(ImageFromPDFFileFlipConvert(glyphPDFOn, CGSizeMake(32, 32), NO)); // 48
				NSData* _size_72x = UIImagePNGRepresentation(ImageFromPDFFileFlipConvert(glyphPDFOn, CGSizeMake(40, 40), NO)); // 72
				
				[_size_48x writeToFile:[portPath stringByAppendingPathComponent:@"SettingsIcon@2x.png"] atomically:YES];
				[_size_72x writeToFile:[portPath stringByAppendingPathComponent:@"SettingsIcon@3x.png"] atomically:YES];
				
				needRespring = YES;
			}
			NSString* glyphPDFOff = nil;
			if(access([bundlePath stringByAppendingPathComponent:@"glyph-modern-off.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOff = [bundlePath stringByAppendingPathComponent:@"glyph-modern-off.pdf"];
			} else if(access([bundlePath stringByAppendingPathComponent:@"glyph-modern.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOff = [bundlePath stringByAppendingPathComponent:@"glyph-modern.pdf"];
			} else if(access([bundlePath stringByAppendingPathComponent:@"glyph-off.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOff = [bundlePath stringByAppendingPathComponent:@"glyph-off.pdf"];
			} else if(access([bundlePath stringByAppendingPathComponent:@"glyph.pdf"].UTF8String, F_OK) == 0) {
				glyphPDFOff = [bundlePath stringByAppendingPathComponent:@"glyph.pdf"];
			}
			if(glyphPDFOff) {
				NSData* size_48x = UIImagePNGRepresentation(ImageFromPDFFileFlipConvert(glyphPDFOff, CGSizeMake(32, 32), YES)); // 48
				NSData* size_72x = UIImagePNGRepresentation(ImageFromPDFFileFlipConvert(glyphPDFOff, CGSizeMake(40, 40), YES)); // 72
				
				[size_48x writeToFile:[portPath stringByAppendingPathComponent:@"Icon-off@2x.png"] atomically:YES];
				[size_72x writeToFile:[portPath stringByAppendingPathComponent:@"Icon-off@3x.png"] atomically:YES];
				
				needRespring = YES;
			}
		}
	}
	if(needRespring) {
		system("killall SpringBoard");
	}
}


static void port_bundle(NSString* bundlePath)
{
	NSString* portPath = getPortedPathFromBundlePath(bundlePath);
	
	if(access(portPath.UTF8String, F_OK) == 0) {
		return;
	}
	
	system([NSString stringWithFormat:@"mkdir -p \"%@\"", portPath].UTF8String);
	system([NSString stringWithFormat:@"echo \"Ported\" >\"%@\"", [portPath stringByAppendingPathComponent:@"flag_ported_flipconvert"]].UTF8String);
	
	NSDictionary* infoOrigPlist = [[NSDictionary alloc] initWithContentsOfFile:[bundlePath stringByAppendingPathComponent:@"Info.plist"]]?:@{};
	
	NSLog(@"infoOrigPlist[%@]: %@", [bundlePath stringByAppendingPathComponent:@"Info.plist"], infoOrigPlist);
	
	NSString* executableName = infoOrigPlist[@"CFBundleExecutable"]?:infoOrigPlist[@"CFBundleDisplayName"]?:@"executable";
	
	system([NSString stringWithFormat:@"ln -s \"%@\" \"%@\"", @"/Library/MobileSubstrate/DynamicLibraries/z_FlipConvert.dylib", [portPath stringByAppendingPathComponent:executableName]].UTF8String);
	
	NSMutableDictionary* infoMut = [infoOrigPlist?:@{} mutableCopy];
	infoMut[@"CFBundleIdentifier"] = infoOrigPlist[@"CFBundleIdentifier"];//[NSString stringWithFormat:@"%@_%@", @"FlipConvert", infoOrigPlist[@"CFBundleIdentifier"]];
	
	infoMut[@"CFBundleExecutable"] = executableName;
	infoMut[@"CFBundleName"] = infoOrigPlist[@"CFBundleName"]?:executableName;
	
	infoMut[@"CFBundleDisplayName"] = infoOrigPlist[@"CFBundleDisplayName"]?:infoMut[@"CFBundleName"];
	
	infoMut[@"NSPrincipalClass"] = [NSString stringWithFormat:@"%@_%@", infoOrigPlist[@"NSPrincipalClass"]?:infoMut[@"CFBundleIdentifier"], @"FlipConvert"];	
	
	infoMut[@"CFBundleDevelopmentRegion"] = @"English";
	infoMut[@"CFBundleInfoDictionaryVersion"] = @"6.0";
	infoMut[@"CFBundlePackageType"] = @"BNDL";
	infoMut[@"CFBundleShortVersionString"] = @"1.0.0";
	infoMut[@"CFBundleSignature"] = @"????";
	infoMut[@"CFBundleVersion"] = @"1.0";
	infoMut[@"DTPlatformName"] = @"iphoneos";
	infoMut[@"MinimumOSVersion"] = @"3.0";
	infoMut[@"CFBundleSupportedPlatforms"] = @[@"iPhoneOS"];
	infoMut[@"UIDeviceFamily"] = @[@(1), @(2),];
	
	[infoMut writeToFile:[portPath stringByAppendingPathComponent:@"Info.plist"] atomically:YES];
	
	
	[bundlePathToMakeImage() addObject:bundlePath];
}

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application
{
	%orig;
	bundlePathMakeImageNow();
}
%end

__attribute__((constructor)) static void initialize_()
{
	dlopen("/usr/lib/libflipswitch.dylib", RTLD_GLOBAL);
	dlopen("/Library/Flipswitch/libFlipswitchSpringBoard.dylib", RTLD_GLOBAL);
	
	%init;
	
	[[NSNotificationCenter defaultCenter] addObserverForName:@"FSSwitchPanelSwitchStateChangedNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		if(note) {
			NSDictionary* userD = [note userInfo];
			NSString* idChange = userD[@"switchIdentifier"];
			if(idChange) {
				FlipConvert_PlaceHolder* instaRep = getValueWithId(idChange, @"ClassRepAlloc");
				if(instaRep) {
					[instaRep refreshState];
				}
			}
		}
	}];
	
	NSArray* fileBundles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Switches/" error:nil]?:@[];
	for(NSString* FileNow in fileBundles) {
		NSString* pathFile = [@"/Library/Switches/" stringByAppendingPathComponent:FileNow];
		port_bundle(pathFile);
		allocForSwitchBundlePath(pathFile);
	}
}