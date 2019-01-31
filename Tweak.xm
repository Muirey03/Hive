#import "funcs.h"

#define mainColor PreferencesColor(@"mainColor", @"FF00A1CA")
#define lblColor PreferencesColor(@"lblColor", @"FFFFFFFF")
#define separatorColor PreferencesColor(@"separatorColor", @"4CFFFFFF")
#define useUnlockAnim PreferencesBool(@"useUnlockAnim", YES)

@implementation HexagonView
-(instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w
{
    CGFloat h = heightForWidth(w);
    CGRect frame = CGRectMake(o.x, o.y, w, h);
    self = [self initWithFrame:frame];
    if (self)
    {
        self.userInteractionEnabled = NO;

        //add observer for unlock animation
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startUnlockAnimation) name:notifStr object:nil];
    }
    return self;
}

-(void)didMoveToWindow
{
    [super didMoveToWindow];

    CAShapeLayer* shapeLayer = [CAShapeLayer layer];
    _path = [UIBezierPath bezierPath];

    CGFloat w = self.frame.size.width;
    NSArray* points = pointsForWidth(w);

    [_path moveToPoint:[points[0] CGPointValue]];
    for (int i = 1; i < 6; i++)
    {
        [_path addLineToPoint:[points[i] CGPointValue]];
    }
    [_path closePath];
    [shapeLayer setPath:[_path CGPath]];
    [shapeLayer setFillColor:[self.fillColor CGColor]];
    [shapeLayer setStrokeColor:[separatorColor CGColor]];
    [[self layer] addSublayer:shapeLayer];
}

-(void)startUnlockAnimation
{
    //screen size
    CGFloat sW = [UIScreen mainScreen].bounds.size.width;
    CGFloat sH = [UIScreen mainScreen].bounds.size.height;

    CGPoint p = [self.superview isKindOfClass:[HexagonButton class]] ? self.superview.center : self.center;

    //get x and y as percentages
    float xPerc = p.x / sW;
    float yPerc = p.y / sH;

    //distances from centre
    float xDist = fabs(0.5 - xPerc);
    float yDist = fabs(0.5 - yPerc);

    //get user's duration value
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"unlockDuration" inDomain:@"com.muirey03.hive"];
    CGFloat animDuration = v ? [v floatValue] : 0.4f;

    //pythag
    float dist = sqrt(xDist*xDist + yDist*yDist);
    CGFloat duration = (dist / sqrt(0.5)) * animDuration;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.superview isKindOfClass:[HexagonButton class]] ? self.superview.alpha = 0 : self.alpha = 0;
        }];
    });
}
@end

static NSMutableArray* oldBtns = [[NSMutableArray alloc] initWithCapacity:10];
static SBUIPasscodeLockViewWithKeypad* lockView;
static NSMutableArray* availableNos;
static BOOL dummyPassInstalled;
static BOOL scramblePassInstalled;

@implementation HexagonButton
-(instancetype)initWithOrigin:(CGPoint)o width:(CGFloat)w
{
    CGFloat h = heightForWidth(w);
    CGRect frame = CGRectMake(o.x, o.y, w, h);
    self = [self initWithFrame:frame];
    if (self)
    {
        hexagon = [[HexagonView alloc] initWithOrigin:CGPointMake(0, 0) width:w];
        [self addSubview:hexagon];
        numLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, h)];
        numLbl.textColor = lblColor;
        numLbl.textAlignment = UITextAlignmentCenter;
        numLbl.font = [numLbl.font fontWithSize:20];
        [self addSubview:numLbl];

        //add darkening view
        UIColor* darkeningColor = [UIColor colorWithWhite:0 alpha:0.3];
        darkeningView = [[HexagonView alloc] initWithOrigin:CGPointMake(0, 0) width:self.frame.size.width];
        darkeningView.fillColor = darkeningColor;
        darkeningView.alpha = 0;
        [self addSubview:darkeningView];
    }
    return self;
}

-(void)touchesBegan:(id)arg1 withEvent:(id)arg2
{
    [UIView animateWithDuration:0.1 animations:^{
        darkeningView.alpha = 1;
    }];

    //press button
    SBPasscodeNumberPadButton* oldBtn = oldBtns[self.buttonNo];
    UIView* pad = [lockView _numberPad];
    [lockView passcodeLockNumberPad:pad keyDown:oldBtn];

    [super touchesBegan:arg1 withEvent:arg2];
}

-(void)touchesEnded:(id)arg1 withEvent:(id)arg2
{
    //remove darkening view
    [UIView animateWithDuration:0.1 animations:^{
        darkeningView.alpha = 0;
    }];

    //press button
    SBPasscodeNumberPadButton* oldBtn = oldBtns[self.buttonNo];
    UIView* pad = [lockView _numberPad];
    [lockView passcodeLockNumberPad:pad keyUp:oldBtn];

    [super touchesEnded:arg1 withEvent:arg2];
}

-(void)setButtonNo:(unsigned int)arg1
{
    unsigned int displayNo = (arg1 == 9 ? 0 : arg1+1);
    if (dummyPassInstalled || scramblePassInstalled)
    {
        NSInteger index = arc4random_uniform(availableNos.count);
        displayNo = [availableNos[index] integerValue];
        [availableNos removeObjectAtIndex:index];
    }
    numLbl.text = [NSString stringWithFormat:@"%d", displayNo];
    if (!scramblePassInstalled)
        _buttonNo = arg1;
    else
        _buttonNo = (displayNo == 0 ? 9 : displayNo-1);
}

-(void)setFillColor:(UIColor*)arg1
{
    hexagon.fillColor = arg1;
    _fillColor = arg1;
}

//stop hexagon hit boxes from overlapping
-(id)hitTest:(CGPoint)arg1 withEvent:(id)arg2
{
    if (CGPathContainsPoint([hexagon.path CGPath], NULL, arg1, NO))
    {
        return [super hitTest:arg1 withEvent:arg2];
    }
    return nil;
}
@end

static BOOL hiveVisible;

%hook SBDashBoardPasscodeViewController
-(void)viewDidLoad
{
    %orig;
    lockView = MSHookIvar<SBUIPasscodeLockViewWithKeypad*>(self, "_passcodeLockView");
    if (lockView)
    {
        UIView* usePassBtn1 = [lockView safeValueForKey:@"_touchIDUsePasscodeButton"];
        UIView* usePassBtn2 = [lockView safeValueForKey:@"_faceIDUsePasscodeButton"];
        if (!isViewVisible(usePassBtn1) && !isViewVisible(usePassBtn2))
        {
            [self createHive:NO];
        }
    }
}

-(void)viewDidDisappear:(BOOL)arg1
{
    %orig;
    hiveVisible = NO;
    availableNos = [@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9] mutableCopy];
}

%new
-(void)createHive:(BOOL)animated
{
    lockView = MSHookIvar<SBUIPasscodeLockViewWithKeypad*>(self, "_passcodeLockView");
    if (lockView)
    {
        hiveVisible = YES;

        /* Hide old keypad: */
        UIView* pad = MSHookIvar<UIView*>([lockView _numberPad], "_numberPad");
        pad.hidden = YES;

        /* Bring label forward: */
        UIView* titleView = lockView.statusTitleView.superview;
        titleView.layer.zPosition = 999;

        if (animated) lockView.alpha = 0;

        /* Create buttons: */
        CGFloat w = widthForStack(pad.frame.size.width, 3);
        CGPoint o1 = CGPointMake((lockView.frame.size.width - w) / 2, pad.superview.frame.origin.y);
        HexagonButton* h1 = [[HexagonButton alloc] initWithOrigin:o1 width:w];
        h1.fillColor = colorForHexagon(h1, mainColor);
        [lockView addSubview:h1];

        NSMutableArray<UIView*>* keypadButtons = [NSMutableArray new];
        NSArray<UIView*>* btns = createButtonsForBtn(h1, mainColor);
        [keypadButtons addObject:btns[0]];
        [keypadButtons addObject:h1];
        [keypadButtons addObject:btns[1]];

        btns = createButtonsUnderBtn(h1, mainColor);
        [keypadButtons addObjectsFromArray:btns];

        btns = createButtonsUnderBtn(btns[1], mainColor);
        [keypadButtons addObjectsFromArray:btns];

        CGPoint o0 = originForSide(keypadButtons[7], 4);
        HexagonButton* h0 = [[HexagonButton alloc] initWithOrigin:o0 width:w];
        h0.fillColor = colorForHexagon(h0, mainColor);
        [lockView addSubview:h0];
        [keypadButtons addObject:h0];

        //add button actions:
        for (int i = 0; i < keypadButtons.count; i++)
        {
            HexagonButton* btn = (HexagonButton*)keypadButtons[i];
            btn.buttonNo = i;
        }

        /* Create other hexagons: */
        //add above:
        CGFloat y = keypadButtons[0].frame.origin.y;
        UIView* lastCentre = keypadButtons[1];
        while (y > 0)
        {
            btns = createHexesAboveHex(lastCentre, mainColor);
            y = btns[0].frame.origin.y;
            lastCentre = btns[1];
        }

        //add below:
        CGPoint oL = originForSide(keypadButtons[9], 5);
        HexagonView* bL = [[HexagonView alloc] initWithOrigin:oL width:w];
        bL.fillColor = colorForHexagon(bL, mainColor);
        [lockView addSubview:bL];

        CGPoint oR = originForSide(keypadButtons[9], 3);
        HexagonView* bR = [[HexagonView alloc] initWithOrigin:oR width:w];
        bR.fillColor = colorForHexagon(bR, mainColor);
        [lockView addSubview:bR];

        y = keypadButtons[9].frame.origin.y + keypadButtons[9].frame.size.height;
        lastCentre = keypadButtons[9];
        while (y < lockView.frame.size.height)
        {
            btns = createHexesUnderHex(lastCentre, mainColor);
            y = btns[1].frame.origin.y + btns[1].frame.size.height;
            lastCentre = btns[1];
        }

        //add to sides:
        CGFloat h = heightForWidth(w);
        CGFloat leftX = originForSide(btns[0], 0).x;
        CGFloat rightX = originForSide(btns[2], 2).x;
        y = btns[1].frame.origin.y + h;
        while (y > 0)
        {
            y -= h;

            CGPoint leftO = CGPointMake(leftX, y);
            HexagonView* lHex = [[HexagonView alloc] initWithOrigin:leftO width:w];
            lHex.fillColor = colorForHexagon(lHex, mainColor);
            [lockView addSubview:lHex];

            CGPoint rightO = CGPointMake(rightX, y);
            HexagonView* rHex = [[HexagonView alloc] initWithOrigin:rightO width:w];
            rHex.fillColor = colorForHexagon(rHex, mainColor);
            [lockView addSubview:rHex];
        }

        if (animated)
        {
            [UIView animateWithDuration:0.3 animations:^{
                lockView.alpha = 1.f;
            }];
        }
    }
}
%end

%hook UILabel
-(void)didMoveToWindow
{
    %orig;
    if ([[self _viewControllerForAncestor] isKindOfClass:%c(SBDashBoardPasscodeViewController)])
    {
        UIView* titleView = lockView.statusTitleView;
        if (titleView == self)
        {
            self.textColor = lblColor;
        }
    }
}
%end

%hook SBUIButton
-(void)didMoveToWindow
{
    %orig;
    #define self ((UIButton*)self)
    if ([[self _viewControllerForAncestor] isKindOfClass:%c(SBDashBoardPasscodeViewController)])
    {
        [self setTitleColor:lblColor forState:UIControlStateNormal];
    }
    #undef self
}
%end

%hook SBSimplePasscodeEntryFieldButton
-(id)initWithFrame:(CGRect)arg1 paddingOutsideRing:(UIEdgeInsets)arg2 useLightStyle:(BOOL)arg3
{
    self = %orig;
    if (self)
    {
        UIColor* __strong& col = MSHookIvar<UIColor*>(self, "_color");
        col = lblColor;
    }
    return self;
}

-(void)didMoveToWindow
{
    %orig;
    #define self ((UIView*)self)
    for (UIView* v in self.subviews)
    {
        v.layer.borderColor = lblColor.CGColor;
    }
    #undef self
}
%end

%hook SBPasscodeNumberPadButton
-(id)initForCharacter:(unsigned int)arg1
{
    self = %orig;
    if (arg1 == 10)
        arg1 = 9;
    oldBtns[arg1] = self;
    return self;
}
%end

%hook SBUIPasscodeLockViewWithKeypad
-(void)_usePasscodeButtonHit
{
    %orig;
    SBDashBoardPasscodeViewController* vc = (SBDashBoardPasscodeViewController*)[self _viewControllerForAncestor];
    if ([vc isKindOfClass:%c(SBDashBoardPasscodeViewController)])
    {
        [vc createHive:YES];
    }
}
%end

/* Super cool fade out animation */
%hook SBCoverSheetSlidingViewController
-(void)_dismissCoverSheetAnimated:(BOOL)arg1 withCompletion:(/*^block*/id)arg2
{
    if (hiveVisible && useUnlockAnim)
    {
        arg1 = NO;

        //start animation
        [[NSNotificationCenter defaultCenter] postNotificationName:notifStr object:nil];

        //get user's duration value
        id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"unlockDuration" inDomain:@"com.muirey03.hive"];
        CGFloat animDuration = v ? [v floatValue] : 0.4f;
        CGFloat padding = animDuration * 0.125;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (animDuration + padding) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            %orig;
        });
    }
    else
    {
        %orig;
    }
}
%end

%ctor
{
    dummyPassInstalled = isDummyPassInstalled();
    scramblePassInstalled = isScramblePassInstalled();
    availableNos = [@[@0, @1, @2, @3, @4, @5, @6, @7, @8, @9] mutableCopy];
}
