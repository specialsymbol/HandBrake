//
//  HBPreviewViewController.m
//  HandBrake
//
//  Created by Damiano Galassi on 14/12/2017.
//

#import <QuartzCore/QuartzCore.h>
#import "HBPreviewViewController.h"

#import "HBPreviewView.h"
#import "HBPreviewGenerator.h"
#import "HBPreviewController.h"

@interface HBPreviewViewController ()

@property (nonatomic, strong) IBOutlet HBPreviewView *previewView;

@property (nonatomic, strong) IBOutlet NSView *hud;

@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) BOOL visible;

@property (nonatomic) NSTimer *hudTimer;
@property (nonatomic) BOOL mouseInView;

@end

@implementation HBPreviewViewController

- (instancetype)init
{
    self = [super initWithNibName:@"HBPreviewViewController" bundle:nil];
    if (self)
    {
        _selectedIndex = 1;
    }
    return self;
}

- (void)loadView
{
    [super loadView];
    self.visible = YES;
    self.previewView.showShadow = NO;

    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.view.frame
                                                                options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingInVisibleRect | NSTrackingActiveAlways
                                                                  owner:self
                                                               userInfo:nil];
    [self.view addTrackingArea:trackingArea];
    self.hud.hidden = YES;
    self.hud.layer.opacity = 0;
}

- (void)viewWillAppear
{
    self.visible = YES;
    [self updatePicture];
}

- (void)viewDidDisappear
{
    self.visible = NO;
}

- (void)setGenerator:(HBPreviewGenerator *)generator
{
    _generator = generator;
    if (generator)
    {
        self.selectedIndex = self.selectedIndex;
        [self updatePicture];
    }
    else
    {
        self.previewView.image = nil;
    }
}

- (void)update
{
    [self updatePicture];
}

#pragma MARK: - HUD

- (void)mouseEntered:(NSEvent *)theEvent
{
    if (self.generator)
    {
        [self showHudWithAnimation:self.hud];
    }
    self.mouseInView = YES;
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [super mouseMoved:theEvent];

    // Test for mouse location to show/hide hud controls
    if (self.generator && self.mouseInView)
    {
        [self showHudWithAnimation:self.hud];
    }
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [self hideHudWithAnimation:self.hud];
    self.mouseInView = NO;
}

#define ANIMATION_DUR 0.15

- (void)showHudWithAnimation:(NSView *)hud
{
    // The standard view animator doesn't play
    // nicely with the Yosemite visual effects yet.
    // So let's do the fade ourself.
    if (hud.layer.opacity == 0 || hud.isHidden)
    {
        hud.hidden = NO;

        [CATransaction begin];
        CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeInAnimation.fromValue = @(hud.layer.presentationLayer.opacity);
        fadeInAnimation.toValue = @(1.0);
        fadeInAnimation.beginTime = 0.0;
        fadeInAnimation.duration = ANIMATION_DUR;

        [hud.layer addAnimation:fadeInAnimation forKey:nil];
        [hud.layer setOpacity:1];

        [CATransaction commit];
    }
}

- (void)hideHudWithAnimation:(NSView *)hud
{
    if (hud.layer.opacity != 0)
    {
        [CATransaction begin];
        CABasicAnimation *fadeOutAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fadeOutAnimation.fromValue = @(hud.layer.presentationLayer.opacity);
        fadeOutAnimation.toValue = @(0.0);
        fadeOutAnimation.beginTime = 0.0;
        fadeOutAnimation.duration = ANIMATION_DUR;

        [hud.layer addAnimation:fadeOutAnimation forKey:nil];
        [hud.layer setOpacity:0];

        [CATransaction commit];
    }
}

#pragma MARK: - Preview index

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    NSInteger count = self.generator.imagesCount;
    if (selectedIndex >= count)
    {
        selectedIndex = count -1;
    }
    else if (selectedIndex < 0)
    {
        selectedIndex = 0;
    }
    _selectedIndex = selectedIndex;
}

- (IBAction)next:(id)sender
{
    self.selectedIndex += 1;
    [self updatePicture];
}

- (IBAction)previous:(id)sender
{
    self.selectedIndex -= 1;
    [self updatePicture];
}

- (void)updatePicture
{
    if (self.generator && self.visible)
    {
        CGImageRef fPreviewImage = [self.generator copyImageAtIndex:self.selectedIndex shouldCache:YES];
        self.previewView.image = fPreviewImage;
        CFRelease(fPreviewImage);
    }
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    if (theEvent.deltaY < 0)
    {
        self.selectedIndex += 1;
        [self updatePicture];
    }
    else if (theEvent.deltaY > 0)
    {
        self.selectedIndex -= 1;
        [self updatePicture];
    }
}

@end
