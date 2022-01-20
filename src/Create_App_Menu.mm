#include "Create_App_Menu.h"

@implementation AppMenu

-(void)createMenu {
    /* Create the app's main menu bar */
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Menu 1"];

    /* Create a menu item for the menu bar */
    NSMenuItem *menuItem1 = [[NSMenuItem alloc] initWithTitle:@"Menu 1" action: NULL keyEquivalent:@""];
    NSMenu *menuItem1Menu = [[NSMenu alloc] initWithTitle:@"Menu 1"];
    [menuItem1 setSubmenu:menuItem1Menu];

    NSMenuItem *appMenu_QuitAppMI = [[NSMenuItem alloc] initWithTitle:@"Quit Example Metal App" action: @selector(quitApp:) keyEquivalent:nil];
    [menuItem1Menu addItem:appMenu_QuitAppMI];

    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:@"File" action: NULL keyEquivalent:@""];
    NSMenu *fileMenuItemMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileMenuItem setSubmenu:fileMenuItemMenu];
    NSMenuItem *openFileMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open an Image" action:@selector(openImage:) keyEquivalent:nil];
    [fileMenuItemMenu addItem: openFileMenuItem];

    [menu addItem:menuItem1];
    [menu addItem:fileMenuItem];
    /*
        Set the app's main menu bar as the menu we created that contains all the other menus and there menus...
    */
    [NSApp setMainMenu:menu];
}

@end