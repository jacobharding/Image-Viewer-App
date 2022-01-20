#include "AppDelegate.h"

@implementation HelloWindowAppDelegate
- (void)quitAppDueToWindowClose {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[[NSApp windows] objectAtIndex:0]];
    [NSApp terminate:self];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [[[NSApp windows] objectAtIndex:0] makeKeyAndOrderFront:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(quitAppDueToWindowClose) name:NSWindowWillCloseNotification object:[[NSApp windows] objectAtIndex:0]];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
}

- (void)someEvent:(id)sender {
    NSLog(@"Something clicked!");
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    NSLog(@"App was started by using it as the app to open a file!");
    return YES;
}

-(void)openImage:(id)sender {
    NSOpenPanel *openImagePanel = [NSOpenPanel openPanel];

    [openImagePanel beginWithCompletionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK && _metalViewDelegate != nil) {
            [_metalViewDelegate setNewImage:[[openImagePanel URLs] objectAtIndex:0]];
        }
        /*TODO https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/UsingtheOpenandSavePanels/UsingtheOpenandSavePanels.html#//apple_ref/doc/uid/TP40010672-CH4-SW1 */
        /* https://developer.apple.com/documentation/appkit/nsopenpanel?language=objc */
    }];

}

- (void)quitApp:(id)sender {
    NSLog(@"Quiting app...");
    [NSApp terminate:self];
}
@end
/* End of App delegate class */
