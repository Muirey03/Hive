#include <math.h>
#import "interfaces.h"
#include <CSColorPicker/CSColorPicker.h>

#define rads(angleDegrees) ((angleDegrees) * M_PI / 180.0)
#define val(p) ([NSValue valueWithCGPoint:p])
#define domainStr @"com.muirey03.hive"
#define notifStr @"com.muirey03.hive-startUnlockAnimation"

inline CGFloat heightForWidth(CGFloat w)
{
    return (w/2)*sqrt(3);
}

inline CGFloat widthForHeight(CGFloat h)
{
    return (h/sqrt(3))*2;
}

inline CGFloat widthForStack(CGFloat screenW, float n)
{
    n = (n*1.5) + 0.5;
    CGFloat h = (screenW*2*sin(rads(60)))/n;
    return widthForHeight(h);
}

inline CGFloat sideLengthForWidth(CGFloat w)
{
    CGFloat h = heightForWidth(w);
    return h/(2*sin(rads(60)));
}

inline UIColor* PreferencesColor(NSString* key, NSString* fallback)
{
    NSString* hexStr = [[NSUserDefaults standardUserDefaults] objectForKey:key inDomain:domainStr] ? [[NSUserDefaults standardUserDefaults] objectForKey:key inDomain:domainStr] : fallback;
    return [UIColor colorFromHexString:hexStr];
}

static BOOL PreferencesBool(NSString* key, BOOL fallback)
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:key inDomain:domainStr] ? [[[NSUserDefaults standardUserDefaults] objectForKey:key inDomain:domainStr] boolValue] : fallback;
}

NSArray* pointsForWidth(CGFloat w)
{
    CGFloat h = heightForWidth(w);
    CGFloat sLen = sideLengthForWidth(w);
    CGPoint p1 = CGPointMake(0, h/2);
    CGPoint p2 = CGPointMake((w-sLen)/2, 0);
    CGPoint p3 = CGPointMake(p2.x+sLen, 0);
    CGPoint p4 = CGPointMake(w, h/2);
    CGPoint p5 = CGPointMake(p2.x+sLen, h);
    CGPoint p6 = CGPointMake(p2.x, h);
    NSArray* points = @[ val(p1), val(p2), val(p3), val(p4), val(p5), val(p6) ];
    return points;
}

CGPoint operator+(const CGPoint &p1, const CGPoint &p2)
{
    CGPoint sum = { p1.x + p2.x, p1.y + p2.y };
    return sum;
}

NSArray* pointsForHexagon(UIView* hex)
{
    NSMutableArray* points = [pointsForWidth(hex.frame.size.width) mutableCopy];
    for (int i = 0; i < 6; i++)
    {
        points[i] = val(hex.frame.origin + [points[i] CGPointValue]);
    }
    return [points copy];
}

CGPoint pointForHexagon(UIView* hex, int index)
{
    return [pointsForHexagon(hex)[index] CGPointValue];
}

CGPoint originForSide(UIView* hex, int index)
{
    CGPoint o;
    CGFloat w = hex.frame.size.width;
    CGFloat h = heightForWidth(w);
    switch (index)
    {
        case 0:
            o = pointForHexagon(hex, 1) + CGPointMake(-w, -(h/2));
            break;
        case 1:
            o = hex.frame.origin + CGPointMake(0, -h);
            break;
        case 2:
            o = pointForHexagon(hex, 2) + CGPointMake(0, -(h/2));
            break;
        case 3:
            o = pointForHexagon(hex, 2) + CGPointMake(0, (h/2));
            break;
        case 4:
            o = pointForHexagon(hex, 0) + CGPointMake(0, (h/2));
            break;
        case 5:
            o = pointForHexagon(hex, 1) + CGPointMake(-w, h/2);
            break;
    }
    return o;
}

/* I DO PERCENTAGES OUT OF 1, GO FUCK YOURSELF! */
// positive values are lighter
UIColor* changeColor(UIColor* col, float percent)
{
    CGFloat r, g, b, a;
    if ([col getRed:&r green:&g blue:&b alpha:&a])
    {
        r *= (1 + percent);
    	g *= (1 + percent);
    	b *= (1 + percent);
        return [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    return nil;
}

UIColor* colorForPoint(CGPoint p, UIColor* mainColor)
{
    //screen size
    CGFloat sW = [UIScreen mainScreen].bounds.size.width;
    CGFloat sH = [UIScreen mainScreen].bounds.size.height;

    //get x and y as percentages
    float xPerc = p.x / sW;
    float yPerc = p.y / sH;

    //distances from centre
    float xDist = fabs(0.5 - xPerc);
    float yDist = fabs(0.5 - yPerc);

    //pythag
    float dist = sqrt(xDist*xDist + yDist*yDist);
    float percent = 0.25 - dist;

    //get user's contrast value
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:@"hiveContrast" inDomain:@"com.muirey03.hive"];
    CGFloat con = v ? [v floatValue] : 1.f;

    percent *= con;

    return changeColor(mainColor, percent);
}

UIColor* colorForHexagon(UIView* hex, UIColor* mainColor)
{
    return colorForPoint(hex.center, mainColor);
}

NSArray* createHexesForHex(UIView* hex, UIColor* mainColor)
{
    HexagonView* left = [[HexagonView alloc] initWithOrigin:originForSide(hex, 5) width:hex.frame.size.width];
    left.fillColor = colorForHexagon(left, mainColor);
    [hex.superview addSubview:left];

    HexagonView* right = [[HexagonView alloc] initWithOrigin:originForSide(hex, 3) width:hex.frame.size.width];
    right.fillColor = colorForHexagon(right, mainColor);
    [hex.superview addSubview:right];

    return @[left, right];
}

NSArray* createHexesUnderHex(UIView* hex, UIColor* mainColor)
{
    HexagonView* centre = [[HexagonView alloc] initWithOrigin:originForSide(hex, 4) width:hex.frame.size.width];
    centre.fillColor = colorForHexagon(centre, mainColor);
    [hex.superview addSubview:centre];

    NSArray* hexes = createHexesForHex(centre, mainColor);
    HexagonView* left = hexes[0];
    HexagonView* right = hexes[1];

    return @[left, centre, right];
}

NSArray* createHexesAboveHex(UIView* hex, UIColor* mainColor)
{
    HexagonView* centre = [[HexagonView alloc] initWithOrigin:originForSide(hex, 1) width:hex.frame.size.width];
    centre.fillColor = colorForHexagon(centre, mainColor);
    [hex.superview addSubview:centre];

    NSArray* hexes = createHexesForHex(centre, mainColor);
    HexagonView* left = hexes[0];
    HexagonView* right = hexes[1];

    return @[left, centre, right];
}

NSArray* createButtonsForBtn(UIView* hex, UIColor* mainColor)
{
    HexagonButton* left = [[HexagonButton alloc] initWithOrigin:originForSide(hex, 5) width:hex.frame.size.width];
    left.fillColor = colorForHexagon(left, mainColor);
    [hex.superview addSubview:left];

    HexagonButton* right = [[HexagonButton alloc] initWithOrigin:originForSide(hex, 3) width:hex.frame.size.width];
    right.fillColor = colorForHexagon(right, mainColor);
    [hex.superview addSubview:right];

    return @[left, right];
}

NSArray* createButtonsUnderBtn(UIView* hex, UIColor* mainColor)
{
    HexagonButton* centre = [[HexagonButton alloc] initWithOrigin:originForSide(hex, 4) width:hex.frame.size.width];
    centre.fillColor = colorForHexagon(centre, mainColor);
    [hex.superview addSubview:centre];

    NSArray* hexes = createButtonsForBtn(centre, mainColor);
    HexagonButton* left = hexes[0];
    HexagonButton* right = hexes[1];

    return @[left, centre, right];
}

BOOL isViewVisible(UIView* v)
{
    if (v == nil || v.superview == nil)
    {
        return NO;
    }
    UIView* current = v;
    while (YES)
    {
        if (current)
        {
            if (current.hidden || current.alpha == 0)
            {
                return NO;
            }
            current = current.superview;
        }
        else
        {
            break;
        }
    }
    return YES;
}
