@interface UIView (internal)
-(UIViewController*)_viewControllerForAncestor;
@end

@interface SBDashBoardPasscodeViewController : UIViewController
-(void)createHive:(BOOL)animated;
@end

@interface SBUIPasscodeLockViewWithKeypad : UIView
@property (nonatomic,retain) UILabel* statusTitleView;
-(id)_numberPad;
-(void)passcodeLockNumberPad:(id)arg1 keyDown:(id)arg2;
-(void)passcodeLockNumberPad:(id)arg1 keyUp:(id)arg2;
@end

@interface SBPasscodeNumberPadButton : UIControl
-(void)touchDown;
-(void)touchUp;
-(unsigned int)character;
@end

@interface NSUserDefaults (internal)
-(id)objectForKey:(id)arg1 inDomain:(id)arg2;
@end

@interface NSObject (internal)
-(id)safeValueForKey:(id)arg1;
@end

#pragma mark new classes
@interface HexagonView : UIView
@property (nonatomic, readonly) UIBezierPath* path;
@property (nonatomic, retain) UIColor* fillColor;
-(instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w;
@end

@interface HexagonButton : UIButton
{
    HexagonView* darkeningView;
    UILabel* numLbl;
    HexagonView* hexagon;
}
@property (nonatomic, retain) UIColor* fillColor;
@property (nonatomic) unsigned int buttonNo;
-(instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w;
@end
#pragma mark end new classes
