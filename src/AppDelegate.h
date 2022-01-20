#include <Cocoa/Cocoa.h>
#include "Hello_Window_MetalView_Delegate.h"

#ifndef __AppDelegate__
#define __AppDelegate__

/* Define a App Delegate class that adheres to the NSApplicationDelegate protocol */
@interface HelloWindowAppDelegate : NSObject <NSApplicationDelegate>

    @property (weak) MetalView_Delegate *metalViewDelegate;
    @property (weak) NSWindow *mainAppWindow;

    - (void)applicationDidFinishLaunching:(NSNotification *)notification;
    - (void)applicationDidBecomeActive:(NSNotification *)notification;
    - (void)someEvent:(id)sender;
    - (void)quitApp:(id)sender;
    - (void)openImage:(id)sender;
@end

#endif