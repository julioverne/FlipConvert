#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "FSSwitchState.h"

@class CCUIContentModuleContext, CCUIToggleViewController, CCUICAPackageDescription;
@interface CCUIToggleModule : NSObject {

	CCUIToggleViewController* _viewController;
	CCUIContentModuleContext* _contentModuleContext;
	CCUICAPackageDescription* _glyphPackageDescription;

}

@property (nonatomic,retain) CCUIContentModuleContext * contentModuleContext;                                                //@synthesize contentModuleContext=_contentModuleContext - In the implementation block
@property (assign,getter=isSelected,nonatomic) BOOL selected; 
@property (nonatomic,copy,readonly) UIImage * iconGlyph; 
@property (nonatomic,copy,readonly) UIImage * selectedIconGlyph; 
@property (nonatomic,copy,readonly) UIColor * selectedColor; 
@property (nonatomic,copy,readonly) CCUICAPackageDescription * glyphPackageDescription;                                      //@synthesize glyphPackageDescription=_glyphPackageDescription - In the implementation block
@property (nonatomic,copy,readonly) NSString * glyphState; 
@property (readonly) unsigned long long hash; 
@property (readonly) Class superclass; 
@property (copy,readonly) NSString * description; 
@property (copy,readonly) NSString * debugDescription; 
@property (nonatomic,readonly) UIViewController* contentViewController; 
@property (nonatomic,readonly) UIViewController * backgroundViewController; 
-(BOOL)isSelected;
-(void)setSelected:(BOOL)arg1 ;
-(UIViewController*)contentViewController;
-(CCUICAPackageDescription *)glyphPackageDescription;
-(NSString *)glyphState;
-(void)reconfigureView;
-(UIImage *)iconGlyph;
-(UIImage *)selectedIconGlyph;
-(id)glyphPackage;
-(CCUIContentModuleContext *)contentModuleContext;
-(void)setContentModuleContext:(CCUIContentModuleContext *)arg1 ;
-(void)refreshState;
-(UIColor *)selectedColor;
@end

@interface FlipConvertLongPressGestureRecognizer : UILongPressGestureRecognizer
@end

@interface FlipConvert_PlaceHolder : CCUIToggleModule <UILongPressGestureRecognizerDelegate>
@property (nonatomic,retain) NSString * flipConvert_id;
@end