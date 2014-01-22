//
//  CWStatusBarNotification.m
//  CWNotificationDemo
//
//  Created by Cezary Wojcik on 11/15/13.
//  Copyright (c) 2013 Cezary Wojcik. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "CWStatusBarNotification.h"

#define STATUS_BAR_ANIMATION_LENGTH 0.25f
#define FONT_SIZE 12.0f
#define PADDING 10.0f
#define SCROLL_SPEED 40.0f
#define SCROLL_DELAY 1.0f

@interface ScrollLabel : UILabel
- (CGFloat)scrollTime;
@end


@implementation CWStatusBarNotification
{
	UIWindow *_notificationWindow;
	UIView *_rootView;
	
	UIView *_statusBarView;
	ScrollLabel *_notificationLabel;
}

@synthesize notificationLabelBackgroundColor, notificationLabelTextColor;

@synthesize notificationStyle, notificationIsShowing;

- (CWStatusBarNotification *)init {
    self = [super init];
    if (self) {
        // set defaults
        self.notificationLabelBackgroundColor = [[UIApplication sharedApplication] delegate].window.tintColor;
        self.notificationLabelTextColor = [UIColor whiteColor];
        self.notificationStyle = CWNotificationStyleStatusBarNotification;
        self.notificationAnimationInStyle = CWNotificationAnimationStyleBottom;
        self.notificationAnimationOutStyle = CWNotificationAnimationStyleBottom;
        self.notificationAnimationType = CWNotificationAnimationTypeReplace;
    }
    return self;
}

# pragma mark - dimensions

- (CGFloat)getStatusBarHeight {
    if (self.notificationLabelHeight > 0) {
        return self.notificationLabelHeight;
    }
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    if (UIDeviceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.width;
    }
    return statusBarHeight > 0 ? statusBarHeight : 20;
}

- (CGFloat)getStatusBarWidth {
    if (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        return [UIScreen mainScreen].bounds.size.width;
    }
    return [UIScreen mainScreen].bounds.size.height;
}

- (CGRect)getNotificationLabelTopFrame {
    return CGRectMake(0, -1*[self getNotificationLabelHeight], [self getStatusBarWidth], [self getNotificationLabelHeight]);
}

- (CGRect)getNotificationLabelLeftFrame {
    return CGRectMake(-1*[self getStatusBarWidth], 0, [self getStatusBarWidth], [self getNotificationLabelHeight]);
}

- (CGRect)getNotificationLabelRightFrame {
    return CGRectMake([self getStatusBarWidth], 0, [self getStatusBarWidth], [self getNotificationLabelHeight]);
}

- (CGRect)getNotificationLabelBottomFrame {
    return CGRectMake(0, [self getNotificationLabelHeight], [self getStatusBarWidth], 0);
}

- (CGRect)getNotificationLabelFrame {
    return CGRectMake(0, 0, [self getStatusBarWidth], [self getNotificationLabelHeight]);
}

- (CGFloat)getNavigationBarHeight {
    if (UIDeviceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ||
        UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return 44.0f;
    }
    return 30.0f;
}

- (CGFloat)getNotificationLabelHeight {
    switch (self.notificationStyle) {
        case CWNotificationStyleStatusBarNotification:
            return [self getStatusBarHeight];
        case CWNotificationStyleNavigationBarNotification:
            return [self getStatusBarHeight] + [self getNavigationBarHeight];
        default:
            return [self getStatusBarHeight];
    }
}

# pragma mark - screen orientation change

- (void)screenOrientationChanged {
    _notificationLabel.frame = [self getNotificationLabelFrame];
    _statusBarView.hidden = YES;
}

# pragma mark - window and views creation

- (UIWindow*)createNotificationWindow
{
	UIWindow *notificationWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    notificationWindow.backgroundColor = [UIColor clearColor];
    notificationWindow.userInteractionEnabled = NO;
    notificationWindow.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    notificationWindow.windowLevel = UIWindowLevelStatusBar;
    notificationWindow.rootViewController = [UIViewController new];
	return notificationWindow;
}

- (ScrollLabel*)createNotificationLabelWithMessage:(NSString *)message
{
    ScrollLabel *notification = [ScrollLabel new];
    notification.numberOfLines = self.multiline ? 0 : 1;
    notification.text = message;
    notification.textAlignment = NSTextAlignmentCenter;
    notification.adjustsFontSizeToFitWidth = NO;
    notification.font = [UIFont systemFontOfSize:FONT_SIZE];
    notification.backgroundColor = self.notificationLabelBackgroundColor;
    notification.textColor = self.notificationLabelTextColor;
	return notification;
}

- (UIView*)createStatusBarView
{
	UIView *barView = [[UIView alloc] initWithFrame:[self getNotificationLabelFrame]];
    barView.clipsToBounds = YES;
    if (self.notificationAnimationType == CWNotificationAnimationTypeReplace) {
        UIView *statusBarImageView = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:YES];
        [barView addSubview:statusBarImageView];
    }
	return barView;
}

# pragma mark - frame changing

- (void)zeroFrameChange
{
	switch (self.notificationAnimationInStyle) {
        case CWNotificationAnimationStyleTop:
            _notificationLabel.frame = [self getNotificationLabelTopFrame];
            break;
        case CWNotificationAnimationStyleBottom:
            _notificationLabel.frame = [self getNotificationLabelBottomFrame];
            break;
        case CWNotificationAnimationStyleLeft:
            _notificationLabel.frame = [self getNotificationLabelLeftFrame];
            break;
        case CWNotificationAnimationStyleRight:
            _notificationLabel.frame = [self getNotificationLabelRightFrame];
            break;
    }
}

- (void)firstFrameChange
{
    _notificationLabel.frame = [self getNotificationLabelFrame];
    switch (self.notificationAnimationInStyle) {
        case CWNotificationAnimationStyleTop:
            _statusBarView.frame = [self getNotificationLabelBottomFrame];
            break;
        case CWNotificationAnimationStyleBottom:
            _statusBarView.frame = [self getNotificationLabelTopFrame];
            break;
        case CWNotificationAnimationStyleLeft:
            _statusBarView.frame = [self getNotificationLabelRightFrame];
            break;
        case CWNotificationAnimationStyleRight:
            _statusBarView.frame = [self getNotificationLabelLeftFrame];
            break;
    }
}

- (void)secondFrameChange
{
    switch (self.notificationAnimationOutStyle) {
        case CWNotificationAnimationStyleTop:
            _statusBarView.frame = [self getNotificationLabelBottomFrame];
            break;
        case CWNotificationAnimationStyleBottom:
			_statusBarView.frame = [self getNotificationLabelTopFrame];
//            self.statusBarView.frame = [self getNotificationLabelTopFrame];
//            self.notificationLabel.layer.anchorPoint = CGPointMake(0.5f, 1.0f);
//            self.notificationLabel.center = CGPointMake(self.notificationLabel.center.x, [self getNotificationLabelHeight]);
            break;
        case CWNotificationAnimationStyleLeft:
            _statusBarView.frame = [self getNotificationLabelRightFrame];
            break;
        case CWNotificationAnimationStyleRight:
            _statusBarView.frame = [self getNotificationLabelLeftFrame];
            break;
    }
}

- (void)thirdFrameChange
{
    _statusBarView.frame = [self getNotificationLabelFrame];
    switch (self.notificationAnimationOutStyle) {
        case CWNotificationAnimationStyleTop:
            _notificationLabel.frame = [self getNotificationLabelTopFrame];
            break;
        case CWNotificationAnimationStyleBottom:
			_notificationLabel.frame = [self getNotificationLabelBottomFrame];
//            self.notificationLabel.transform = CGAffineTransformMakeScale(1.0f, 0.0f);
            break;
        case CWNotificationAnimationStyleLeft:
            _notificationLabel.frame = [self getNotificationLabelLeftFrame];
            break;
        case CWNotificationAnimationStyleRight:
            _notificationLabel.frame = [self getNotificationLabelRightFrame];
            break;
    }
}

# pragma mark - display notification

- (void)displayNotificationWithMessage:(NSString *)message completion:(void (^)(void))completion
{
    if (!self.notificationIsShowing) {
        self.notificationIsShowing = YES;
        
        _notificationWindow = [self createNotificationWindow];
        _notificationLabel = [self createNotificationLabelWithMessage:message];
		_statusBarView = [self createStatusBarView];
		
		_rootView = _notificationWindow.rootViewController.view;
		_rootView.bounds = [self getNotificationLabelFrame];
		[_rootView addSubview:_statusBarView];
		[_rootView addSubview:_notificationLabel];

		_notificationWindow.hidden = NO;
        // checking for screen orientation change
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenOrientationChanged) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        
        // animate
		[self zeroFrameChange];
        [UIView animateWithDuration:STATUS_BAR_ANIMATION_LENGTH animations:^{
            [self firstFrameChange];
        } completion:^(BOOL finished) {
            double delayInSeconds = [_notificationLabel scrollTime];
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [completion invoke];
            });
        }];
    }

}

- (void)dismissNotification
{
    if (self.notificationIsShowing) {
        [self secondFrameChange];
        [UIView animateWithDuration:STATUS_BAR_ANIMATION_LENGTH animations:^{
            [self thirdFrameChange];
        } completion:^(BOOL finished) {
            [_notificationLabel removeFromSuperview];
            [_statusBarView removeFromSuperview];
            _notificationWindow = nil;
            self.notificationIsShowing = NO;
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
        }];
    }
}

- (void)displayNotificationWithMessage:(NSString *)message forDuration:(CGFloat)duration
{
    [self displayNotificationWithMessage:message completion:^{
        double delayInSeconds = duration;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self dismissNotification];
        });
    }];
}

@end

@implementation ScrollLabel {
    UIImageView *textImage;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        textImage = [[UIImageView alloc] init];
        [self addSubview:textImage];
    }
    return self;
}

- (CGFloat)fullWidth {
    return [self.text sizeWithAttributes:@{NSFontAttributeName: self.font}].width;
}

- (CGFloat)scrollOffset {
    if (self.numberOfLines != 1) return 0;

    CGRect insetRect = CGRectInset(self.bounds, PADDING, 0);
    return MAX(0, [self fullWidth] - insetRect.size.width);
}

- (CGFloat)scrollTime {
    return ([self scrollOffset] > 0) ? [self scrollOffset] / SCROLL_SPEED + SCROLL_DELAY : 0;
}

- (void)drawTextInRect:(CGRect)rect {
    if ([self scrollOffset] > 0) {
        rect.size.width = [self fullWidth] + PADDING * 2;
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
        [super drawTextInRect:rect];
        textImage.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [textImage sizeToFit];
        [UIView animateWithDuration:[self scrollTime] - SCROLL_DELAY
                              delay:SCROLL_DELAY
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             textImage.transform = CGAffineTransformMakeTranslation(-[self scrollOffset], 0);
                         } completion:^(BOOL finished) {
                         }];
    } else {
        textImage.image = nil;
        [super drawTextInRect:CGRectInset(rect, PADDING, 0)];
    }
}


@end
