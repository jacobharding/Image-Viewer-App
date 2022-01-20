#include "OptionSelectorControl.h"
#include "Utilities.h"
#include "OptionSelectorControlDropDownPanel.h"

@implementation OptionSelectorControl {
    SEL _selectHandlerMethod;
}

-(void)mouseDown:(NSEvent *)e {
    if (self.dropDownPanel.hidden) {
        self.dropDownPanel.hidden = NO;

        _mouseEventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:(NSEventMaskLeftMouseDown) handler:^ NSEvent *(NSEvent *event) {
            NSPoint nullPoint;
            nullPoint.x = 0;
            nullPoint.y = 0;
            NSPoint c1 = [self convertPoint:event.locationInWindow fromView:nil];
            NSPoint c2 = [_dropDownPanel convertPoint:event.locationInWindow fromView:nil];
            NSRect controlRect;
            controlRect.size = self.frame.size;
            controlRect.origin = nullPoint;
            NSRect dropDownPanelRect;
            dropDownPanelRect.size = _dropDownPanel.frame.size;
            dropDownPanelRect.origin = nullPoint;

            BOOL inControlRect = NSPointInRect(c1, controlRect);
            BOOL inDropDownPanelRect = NSPointInRect(c2, dropDownPanelRect);

            BOOL clickNotInControlOrDropDownPanel = !(inControlRect || inDropDownPanelRect);

            if (clickNotInControlOrDropDownPanel) {
                self.dropDownPanel.hidden = YES;
            }
            /* Remove the event monitor after the first time it runs */
            [self removeMouseEventMonitor];
            return event;
        }];

    } else {
        self.dropDownPanel.hidden = YES;

        if (_mouseEventMonitor != nil) {
            [NSEvent removeMonitor:_mouseEventMonitor];
            _mouseEventMonitor = nil;
        }

    }
}

-(void)removeMouseEventMonitor {
    //NSLog(@"Removing mouse event monitor");
    if (_mouseEventMonitor != nil) {
        [NSEvent removeMonitor:_mouseEventMonitor];
        _mouseEventMonitor = nil;
    }
}

-(SEL)selectHandlerMethod {
    return _selectHandlerMethod;
}

-(void)viewDidMoveToWindow {
    /* Add the OptionSelectorControl's dropdown panel view to the window the OptionSelectorControl was added to*/
    [self.window.contentView addSubview:_dropDownPanel];
    //NSLog(@"Added dropdown panel to window");
}

-(void)changeSelectedOption:(int)indexOfNewOption withCTLine:(CTLineRef)ctLine {
    //CFRelease(_selectedOptionCTLineRef);
    _selectedOptionCTLineRef = ctLine;
    
    /*
    NSLog(@"**change selected option");

    if (_selectedOptionCTLineRef == nil) {
        NSLog(@"**_selectedOptionCTLineRef is nil");
    } else {
        NSLog(@"**_selectedOptionCTLineRef is not nil");
    }
    */

    /* Redraw the view */
    [self setNeedsDisplay:YES];
}

-(void)optionSelectorControlFrameHasChanged:(NSNotification *)notification {
    /*
        Position the view and the text in the view
    */
    CGRect textBounds = CTLineGetImageBounds(_selectedOptionCTLineRef, [[NSGraphicsContext currentContext] CGContext]);
    // NSLog(@"textBounds w: %f, h: %f", textBounds.size.width, textBounds.size.height);

    /* Set the size of the view */
    NSSize viewSize;
    //viewSize.width = (textBounds.size.width + 10.0 + textBounds.size.height + 20.0);
    viewSize.height = (textBounds.size.height + 10.0);
    /* viewSize.height = drop down button width */
    viewSize.width = viewSize.height + _dropDownPanel.dropDownPanelSize.width;
    [self setFrameSize:viewSize];

    /* Set the position of the view to be centered in its superview vertically */
    NSPoint viewOrigin;
    viewOrigin.x = 3.0;
    //NSLog(@"viewSize.height: %f", viewSize.height);
    //NSLog(@"self.superview.bounds.size.height: %f", self.superview.bounds.size.height);
    viewOrigin.y = (self.superview.bounds.size.height/2.0) - (viewSize.height/2.0);
    //NSLog(@"viewOrigin: x: %f, y: %f", viewOrigin.x, viewOrigin.y);
    [self setFrameOrigin:viewOrigin];

    /*
        Set the positioning of the text for the selected option
    */
    CGFloat textVerticalPositioning = (self.bounds.size.height/2.0) - (textBounds.size.height/2.0);
    _selectedOptionTextDrawPos.x = 10;
    _selectedOptionTextDrawPos.y = textVerticalPositioning;

    /*
        Set the positioning of the dropdown panel
    */
    NSPoint dropDownPanelLocation = [self.window.contentView convertPoint:self.frame.origin fromView:self.superview];
    dropDownPanelLocation.y = dropDownPanelLocation.y - _dropDownPanel.frame.size.height;
    [_dropDownPanel positionDropDownPanel:dropDownPanelLocation];
    //NSPoint windowCoordinates = [self.window.contentView convertPoint:self.frame.origin fromView:self.superview];
    //_dropDownPanel.frame = NSMakeRect(windowCoordinates.x, windowCoordinates.y - 200, 250, 200);
}

-(instancetype)initWithFrame:(NSRect)frame options:(NSArray<NSString *> *)options selectHandlerObject:(NSObject *)handler selectHandlerMethod:(SEL)handlerMethod {
    self = [super initWithFrame:frame];

    if (self) {

        _selectHandlerObject = handler;
        _selectHandlerMethod = handlerMethod;
        /*  */
        _options = options;
        _font = [NSFont fontWithName:@"ArialMT" size:16.0];
        _mouseEventMonitor = nil;

        if (_font == nil) {
            NSLog(@"Error did not load font");
        } else {
            NSLog(@"Successfully loaded font");
        }

        /* These are set to the correct values in optionSelectorControlFrameHasChanged when the  
            NSApplicationDidFinishLaunchingNotification notification is recieved. The position and size of the
            view and the text in the view depend on the size and position of the superview which can be
            assured to be set after NSApplicationDidFinishLaunchingNotification.
        */
        _selectedOptionTextDrawPos.x = 0;
        _selectedOptionTextDrawPos.y = 0;

        _dropDownPanelVisible = NO;
        _dropDownPanel = [[OptionSelectorControlDropDownPanel alloc] initWithFrame:CGRectMake(0, 0, 250, 200) optionSelectorControl:self options:options indexOfSelectedOption:0];
        _dropDownPanel.wantsLayer = YES;
        _dropDownPanel.hidden = YES;
        [self setPostsFrameChangedNotifications:YES];

        _selectedOptionCTLineRef = (CTLineRef) CFArrayGetValueAtIndex([_dropDownPanel textOptionLines], [_dropDownPanel indexOfSelectedOption]);


        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionSelectorControlFrameHasChanged:) name:NSViewFrameDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionSelectorControlFrameHasChanged:) name:NSWindowDidResizeNotification object:[self window]];
        if (NSApp) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(optionSelectorControlFrameHasChanged:) name:NSApplicationDidFinishLaunchingNotification object:NSApp];
        }

        /* https://developer.apple.com/documentation/appkit/nsimage/1519955-initbyreferencingfile?language=objc */
        NSImage *img1 = [NSImage imageNamed:@"dropdownArrow.png"];

        if (img1 == nil) {
            NSLog(@"Error. Could not load dropdownArrow.png from OptionSelectorControl initialization");
        } else {
            _dropdownArrowImg = [img1 CGImageForProposedRect:nil context:nil hints:nil];
        }
    } else {
        NSLog(@"Failed to initialize Option Selector Control");
    }
    return self;
}

- (void)resetCursorRects {
    [self addCursorRect:CGRectMake(self.bounds.size.width - self.bounds.size.height, 0, self.bounds.size.height, self.bounds.size.height) cursor:[NSCursor pointingHandCursor]];
}

/*
-(void)cursorUpdate:(NSEvent *)e {
    [[NSCursor pointingHandCursor] set];
}
*/

-(void)drawRect:(NSRect)dirtyRect {
    /* Draw Background of Option Selector */
    CGContextRef drawingContext = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetRGBFillColor(drawingContext, 0.7, 0.7, 0.7, 1.0);
    CGContextFillRect(drawingContext, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));

    // Draw the Drop Down Button */
    CGContextSetRGBFillColor(drawingContext, 0.5, 0.5, 0.5, 1.0);
    CGContextFillRect(drawingContext, CGRectMake(self.bounds.size.width - self.bounds.size.height, 0, self.bounds.size.height, self.bounds.size.height));
    CGContextDrawImage(drawingContext, CGRectMake(self.bounds.size.width - self.bounds.size.height, 0, self.bounds.size.height, self.bounds.size.height), _dropdownArrowImg);

    /* Draw the text for the selected option */
    CGContextSetTextPosition(drawingContext, _selectedOptionTextDrawPos.x, _selectedOptionTextDrawPos.y);
    CTLineDraw(_selectedOptionCTLineRef, drawingContext);
}

-(void)dealloc {
    //CFRelease(_selectedOptionAttributedStringRef);
    //CFRelease(_selectedOptionCTLineRef);
    NSLog(@"dealloc for OptionSelectorControl completed");
}

@end