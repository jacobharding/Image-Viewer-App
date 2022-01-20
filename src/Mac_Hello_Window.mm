#include <Cocoa/Cocoa.h>
#include <Foundation/Foundation.h>
#include <MetalKit/MetalKit.h>
#include <Metal/Metal.h>
#include <QuartzCore/QuartzCore.h>

#include "Hello_Window_MetalView_Delegate.h"
#include "Create_App_Menu.h"
#include "AppDelegate.h"
#include "OptionSelectorControl.h"
#include "TestView.h"

int main(int argc, char* argv[]) {
    /*
    if (__has_feature(objc_arc)) {
        //printf("has arc");
        NSLog(@"has arc");
    } else {
        //printf("no arc");
        NSLog(@"no arc");
    }
    */

    @autoreleasepool{

    /* Details on NSApplication: https://developer.apple.com/documentation/appkit/nsapplication */
    /* Docs for this class method of NSApplication: https://developer.apple.com/documentation/appkit/nsapplication/1428360-sharedapplication?language=objc */
    /* Creates the global app instance NSApp */
    NSApplication *app = [NSApplication sharedApplication]; // Call the NSApplication's class method 'shared' to create an instance of NSApplication

    /*
        Get a rectangle for the user's screen size to use to make the window created below fill the user's screen
    */
    NSRect mainScreen = [[NSScreen mainScreen] frame];
    mainScreen.origin.x = 0;
    mainScreen.origin.y = (mainScreen.size.height/2.0);
    mainScreen.size.width = (mainScreen.size.width/2.0);
    mainScreen.size.height = (mainScreen.size.height/2.0);


    /* 
        Create the main window for the app 
    */
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;  /* Create an object for the window's style which is an oring of multiple constants */
    NSWindow *appWindow = [[NSWindow alloc] initWithContentRect:mainScreen
                                            styleMask:styleMask
                                            backing:NSBackingStoreBuffered
                                            defer:NO]; /* Create and instance of the window. initWithContentRect:styleMask:backing:defer: method docs: https://developer.apple.com/documentation/appkit/nswindow/1419477-initwithcontentrect?language=objc */
    [appWindow setTitle:@"Example Metal App"];


    [[appWindow contentView] setWantsLayer:YES];
    appWindow.contentView.layer.masksToBounds = NO;

    /*
        Create the app menu
    */
    AppMenu* appMenu = [[AppMenu alloc] init];
    [appMenu createMenu];

    /*
        Create an MTKView for putting gpu rendered graphics into
    */
    CGPoint metalViewOrigin;
    metalViewOrigin.x = 10.0;
    metalViewOrigin.y = 10.0;
    CGSize metalViewSize;
    metalViewSize.height = 0;
    metalViewSize.width = 0;
    CGRect metalViewRect;
    metalViewRect.origin = metalViewOrigin;
    metalViewRect.size = metalViewSize;
    id<MTLDevice> defaultMetalDevice = MTLCreateSystemDefaultDevice(); /* Must link to CoreGraphics framework */
    MTKView *metalView = [[MTKView alloc] initWithFrame:metalViewRect device:defaultMetalDevice];

    id<MTKViewDelegate> metalViewDelegate = [[MetalView_Delegate alloc] initWithMetalView:metalView];
    [metalView setDelegate:metalViewDelegate];

    metalView.colorspace = NSScreen.mainScreen.colorSpace.CGColorSpace;

    [metalView setPaused:YES];
    [metalView setEnableSetNeedsDisplay:YES];

    id options[] = {@"Linear Interpolation", @"Bilinear Interpolation", @"Bicubic Interpolation"};
    NSArray<NSString *> *optionsArray = [NSArray arrayWithObjects:options count:3];
    OptionSelectorControl *imageInterpolationSelector = [[OptionSelectorControl alloc] initWithFrame:NSMakeRect(0,0,0,0) options:optionsArray selectHandlerObject:metalViewDelegate selectHandlerMethod:@selector(changeInterpolationMethod:)];
    imageInterpolationSelector.wantsLayer = YES;
    [[imageInterpolationSelector layer] setBackgroundColor:[[NSColor colorWithSRGBRed:0.9 green:0.9 blue:0.9 alpha:1.0] CGColor]]; /* set background color of NSView's (buttonAndTextFieldStackView) layer (CALayer) property */
    [imageInterpolationSelector setTranslatesAutoresizingMaskIntoConstraints:NO];
    [imageInterpolationSelector setAutoresizingMask:NSViewNotSizable];

    /*
        Create a stack view to put the button and other views in.
        It will provide a default horizontal or vertical layout for the views it contains (to be the button)
    */
    NSView *buttonAndTextFieldStackView = [[NSView alloc] init];
    [buttonAndTextFieldStackView addSubview:imageInterpolationSelector];
    [buttonAndTextFieldStackView setWantsLayer:YES];
    [[buttonAndTextFieldStackView layer] setMasksToBounds:NO];
    [buttonAndTextFieldStackView setAutoresizesSubviews:NO];

    /*
        Add the two main views (buttonAndTextFieldStackView and metalView) to the root view of the window (the contentView NSView property of the NSWindow appWindow)
    */
    [[appWindow contentView] addSubview:metalView]; /* Add the stack view which contains the button and textfield to the window's content view */
        [[appWindow contentView] addSubview:buttonAndTextFieldStackView]; /* Add the stack view which contains the button and textfield to the window's content view */

    NSLayoutConstraint *stackViewHeight = [NSLayoutConstraint constraintWithItem: buttonAndTextFieldStackView
                        attribute:NSLayoutAttributeHeight
                        relatedBy:NSLayoutRelationEqual
                        toItem: nil
                        attribute:NSLayoutAttributeNotAnAttribute
                        multiplier:1.0
                        constant:30];
    [stackViewHeight setActive:YES];

    /*
        Top stack view bar layout constraints
    */
    NSLayoutConstraint *pinLeft = [NSLayoutConstraint constraintWithItem: buttonAndTextFieldStackView
                        attribute: NSLayoutAttributeLeading 
                        relatedBy: NSLayoutRelationEqual
                        toItem:[appWindow contentView] 
                        attribute: NSLayoutAttributeLeading
                        multiplier:1.0
                        constant:0];
    [pinLeft setActive:YES];
    
    NSLayoutConstraint *pinRight = [NSLayoutConstraint constraintWithItem: buttonAndTextFieldStackView
                        attribute:NSLayoutAttributeTrailing
                        relatedBy:NSLayoutRelationEqual
                        toItem:[appWindow contentView] 
                        attribute:NSLayoutAttributeTrailing
                        multiplier:1.0
                        constant:-0];
    [pinRight setActive:YES];
    
    NSLayoutConstraint *pinTop = [NSLayoutConstraint constraintWithItem: buttonAndTextFieldStackView
                        attribute: NSLayoutAttributeTop 
                        relatedBy: NSLayoutRelationEqual
                        toItem:[appWindow contentView] 
                        attribute: NSLayoutAttributeTop
                        multiplier:1.0
                        constant:0];
    [pinTop setActive:YES];
    
    NSLayoutConstraint *pinBottom = [NSLayoutConstraint constraintWithItem: buttonAndTextFieldStackView
                        attribute:NSLayoutAttributeBottom
                        relatedBy:NSLayoutRelationEqual
                        toItem:metalView
                        attribute:NSLayoutAttributeTop
                        multiplier:1.0
                        constant:-0];
    [pinBottom setActive:YES];
    
    /*
        MTKView layout constraints
    */
    NSLayoutConstraint *pinLeftMetalView = [NSLayoutConstraint constraintWithItem: metalView
                        attribute:NSLayoutAttributeLeading
                        relatedBy:NSLayoutRelationEqual
                        toItem:[appWindow contentView]
                        attribute:NSLayoutAttributeLeading
                        multiplier:1.0
                        constant: 0];
    [pinLeftMetalView setActive:YES];
    
    NSLayoutConstraint *pinRightMetalView = [NSLayoutConstraint constraintWithItem: metalView
                        attribute:NSLayoutAttributeTrailing
                        relatedBy:NSLayoutRelationEqual
                        toItem:[appWindow contentView]
                        attribute:NSLayoutAttributeTrailing
                        multiplier:1.0
                        constant:-0];
    [pinRightMetalView setActive:YES];
    
    NSLayoutConstraint *pinBottomMetalView = [NSLayoutConstraint constraintWithItem: metalView
                        attribute:NSLayoutAttributeBottom
                        relatedBy:NSLayoutRelationEqual
                        toItem:[appWindow contentView] 
                        attribute:NSLayoutAttributeBottom
                        multiplier:1.0
                        constant:-0];
    [pinBottomMetalView setActive:YES];


    /* 
        Set the background color for the stackview container
    */
    [buttonAndTextFieldStackView setWantsLayer:YES]; /* set the view to have a layer background: https://developer.apple.com/documentation/appkit/nsview/1483695-wantslayer?language=objc */
    [[buttonAndTextFieldStackView layer] setBackgroundColor:[[NSColor colorWithSRGBRed:0.8 green:0.8 blue:0.8 alpha:1.0] CGColor]]; /* set background color of NSView's (buttonAndTextFieldStackView) layer (CALayer) property */

    /*
        Make the layout constraints of the MTKView not be created from the autoResizingMask.
    */
    [metalView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [buttonAndTextFieldStackView setTranslatesAutoresizingMaskIntoConstraints:NO];

    /*
        Set the background color for the main app window
    */
    [appWindow setBackgroundColor:[NSColor colorWithSRGBRed:0.5 green:0.5 blue:0.5 alpha:1.0]];

    /* Have to set this for the app's menu bar to be displayed */
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    /* Have to set this for that the menu items are displayed */
    [NSApp setPresentationOptions:NSApplicationPresentationDefault];
    
    /* Create a delegate object for the app */
    HelloWindowAppDelegate *appDelegate = [[HelloWindowAppDelegate alloc] init];
    [appDelegate setMetalViewDelegate:metalViewDelegate];
    [NSApp setDelegate:appDelegate];

    /* Runs the event loop */
    [NSApp run];

    } /* End of @autoreleasepool. This has to go after [NSApp run] or the menu is disabled */

    return 0;
}