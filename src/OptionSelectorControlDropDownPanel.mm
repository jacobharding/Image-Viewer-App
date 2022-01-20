#include "OptionSelectorControlDropDownPanel.h"
#include "Utilities.h"

#include "OptionSelectorControl.h"


@interface OptionTrackingRectInfoStruct : NSObject
@property int optionNumber;
-(instancetype)initWithOptionNumber:(int)optionNumber;
@end

@implementation OptionTrackingRectInfoStruct
-(instancetype)initWithOptionNumber:(int)optionNumber {
    self = [super init];
    if (!self) {
        NSLog(@"Error instantiating OptionTrackingRectInfoStruct");
        return self;
    }
    _optionNumber = optionNumber;
    return self;
}
@end

@implementation  OptionSelectorControlDropDownPanel

-(void)mouseDown:(NSEvent *)e {
    for (int i = 0; i < _numberOfOptions; i++) {
        if (_optionIsHovered[i]) {
            [self setHidden:YES];
            _indexOfSelectedOption = i;
            [self recalculateOptionRects];
            [self setNeedsDisplay:YES];
            [[self optionSelectorControl] changeSelectedOption:i withCTLine:(CTLineRef) CFArrayGetValueAtIndex(_textOptionLines, (long) i)];
            
            IMP aIMP = [[[self optionSelectorControl] selectHandlerObject] methodForSelector:[[self optionSelectorControl] selectHandlerMethod]];
            void (*callbackSelector)(id, SEL, NSNumber *) = (void (*)(id, SEL, NSNumber *))aIMP;
            callbackSelector([[self optionSelectorControl] selectHandlerObject], [[self optionSelectorControl] selectHandlerMethod], [NSNumber numberWithInt:i]);
            return;
        }
    }
}

/* https://developer.apple.com/documentation/appkit/nsview/1483719-updatetrackingareas?language=objc */
/* Override method */
-(void)updateTrackingAreas {
    //NSLog(@"updateTrackingAreas");
}

-(void)recalculateOptionRects {

    NSSize dropDownPanelSize;
    float panelWidth = 0;
    float panelHeight = ((_optionVerticalPadding*2)*(_numberOfOptions - 1)) + ((_numberOfOptions - 2) * 1);
    
    /* For every option given */
    for (int i = 0; i < _numberOfOptions; i++) {
        _optionIsHovered[i] = 0; /* default to none of the options having a focus background */
        

        NSRect optionRect;
        optionRect.origin.x = 0;

        CGRect optionTextBounds = CTLineGetImageBounds((CTLineRef) CFArrayGetValueAtIndex(_textOptionLines, (long) i), [[NSGraphicsContext currentContext] CGContext]);
        NSPoint optionTextOrigin;

        float optionBoxHeight = optionTextBounds.size.height + (_optionVerticalPadding*2);
        optionRect.size.height = optionBoxHeight;
        if (_indexOfSelectedOption < i) {
            /* (optionBoxHeight + 1): plus 1 to prevent two options having focus at the same time */
            optionTextOrigin.y = _optionVerticalPadding + ((optionBoxHeight + 1) * (_numberOfOptions - 1 - i));
            optionRect.origin.y = (optionBoxHeight + 1) * (_numberOfOptions - 1 - i);
        } else {
            optionTextOrigin.y = _optionVerticalPadding + ((optionBoxHeight + 1) * (_numberOfOptions - 1 - i - 1));
            optionRect.origin.y = (optionBoxHeight + 1) * (_numberOfOptions - 1 - i - 1);
        }

        _optionRectsArray[i] = optionRect;

        optionTextOrigin.x = _horizontalPadding;
        _textPositionsOfOptions[i] = optionTextOrigin;

        /* Don't increment the height of the drop down panel for the selected option as it isn't in the panel when selected */
        if (i != _indexOfSelectedOption) {
            panelHeight += optionTextBounds.size.height;
        }

        /* Set the width of the panel to the width of the option whose text width is the greatest */
        if (optionTextBounds.size.width > panelWidth) {
            panelWidth = optionTextBounds.size.width;
        }
    }

    dropDownPanelSize.width = panelWidth + (2*_horizontalPadding);
    dropDownPanelSize.height = panelHeight;
    [self setFrameSize:dropDownPanelSize];

    /* Remove all old tracking areas */
    for (id ta in [self trackingAreas]) {
        [self removeTrackingArea:ta];
    }

    /* Create and add new tracking areas based on new positioning and selected option */
    for (int i = 0; i < _numberOfOptions; i++) {
        _optionRectsArray[i].size.width = dropDownPanelSize.width;
        /* Add tracking areas for all the non selected options */
        if (_indexOfSelectedOption != i) {
            OptionTrackingRectInfoStruct *tempTrackingAreaInfoStruct = [[OptionTrackingRectInfoStruct alloc] initWithOptionNumber:i];
            NSDictionary *optionTrackingAreaRectDictionary = @{ @"option": tempTrackingAreaInfoStruct};
            NSTrackingArea *optionTrackingArea = [[NSTrackingArea alloc] initWithRect:_optionRectsArray[i]
                                                                    options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) 
                                                                    owner:self 
                                                                    userInfo:optionTrackingAreaRectDictionary];
            [self addTrackingArea: optionTrackingArea];
        }
    }
}

-(instancetype)initWithFrame:(NSRect)frame optionSelectorControl:(OptionSelectorControl *)optionSelectorControl options:(NSArray<NSString *> *)options indexOfSelectedOption:(int)indexOfSelectedOption{
    self = [super initWithFrame:frame];
    _optionSelectorControl = optionSelectorControl;
    self.layer.backgroundColor = [[NSColor colorWithSRGBRed:0.7 green:0.7 blue:0.7 alpha:1.0] CGColor];

    if (!self) {
        NSLog(@"Error in initializer of OptionSelectorControlDropDownPanel");
        return self;
    }

    /* Initialize the _textOptionLines CFArray */
    _textOptionLines = CFArrayCreateMutable(kCFAllocatorDefault, (long)[options count], &kCFTypeArrayCallBacks);
    /* Initialize textPositionsOfOptions array */
    _textPositionsOfOptions = (NSPoint *) malloc(sizeof(NSPoint)*[options count]);
    /* Initialize font to use for all the text options */
    _font = [NSFont fontWithName:@"ArialMT" size:16.0];
    
    _indexOfSelectedOption = indexOfSelectedOption;
    _optionIsHovered = (int *) malloc(sizeof(int)*[options count]);

    if (_font == nil) {
        NSLog(@"Error did not load font");
    } else {
        NSLog(@"Successfully loaded font");
    }

    _horizontalPadding = 10;
    _optionVerticalPadding = 5;
    _numberOfOptions = [options count];

    //NSSize dropDownPanelSize;
    float panelWidth = 0;
    float panelHeight = ((_optionVerticalPadding*2)*([options count] - 1)) + (([options count] - 2) * 1);
    
    _optionRectsArray = (NSRect*) malloc(sizeof(NSRect)*([options count]));
    //int numberOfOptions = [options count];

    /* For every option given */
    for (int i = 0; i < _numberOfOptions; i++) {
        _optionIsHovered[i] = 0; /* default to none of the options having a focus background */

        /* Create attributed string for the option */
        NSDictionary *optionStringDictionary = @{ NSFontAttributeName: _font};
        CFDictionaryRef optionAttributedStringAttributes = (__bridge CFDictionaryRef)optionStringDictionary;
        CFStringRef optionStringRef = (__bridge CFStringRef) options[i];
        CFAttributedStringRef optionAttributedStringRef = CFAttributedStringCreate(kCFAllocatorDefault, optionStringRef, optionAttributedStringAttributes);

        if (optionAttributedStringRef == NULL) {
            NSLog(@"Error making attributed string in OptionSelectorControlDropDownPanel");
        }

        NSRect optionRect;
        optionRect.origin.x = 0;

        /* Create the CTLine for the option */
        CTLineRef temp = CTLineCreateWithAttributedString(optionAttributedStringRef);
        CFArrayAppendValue(_textOptionLines, temp);

        CGRect optionTextBounds = CTLineGetImageBounds(temp, [[NSGraphicsContext currentContext] CGContext]);

        NSPoint optionTextOrigin;

        float optionBoxHeight = optionTextBounds.size.height + (_optionVerticalPadding*2);
        optionRect.size.height = optionBoxHeight;
        if (indexOfSelectedOption < i) {
            /* (optionBoxHeight + 1): plus 1 to prevent two options having focus at the same time */
            optionTextOrigin.y = _optionVerticalPadding + ((optionBoxHeight + 1) * (_numberOfOptions - 1 - i));
            optionRect.origin.y = (optionBoxHeight + 1) * (_numberOfOptions - 1 - i);
        } else {
            optionTextOrigin.y = _optionVerticalPadding + ((optionBoxHeight + 1) * (_numberOfOptions - 1 - i - 1));
            optionRect.origin.y = (optionBoxHeight + 1) * (_numberOfOptions - 1 - i - 1);
        }

        _optionRectsArray[i] = optionRect;

        optionTextOrigin.x = _horizontalPadding;
        _textPositionsOfOptions[i] = optionTextOrigin;

        /* Don't increment the height of the drop down panel for the selected option as it isn't in the panel when selected */
        if (i != indexOfSelectedOption) {
            panelHeight += optionTextBounds.size.height;
        }

        /* Set the width of the panel to the width of the option whose text width is the greatest */
        if (optionTextBounds.size.width > panelWidth) {
            panelWidth = optionTextBounds.size.width;
        }

        CFRelease(optionAttributedStringAttributes);
        CFRelease(optionAttributedStringRef);
        CFRelease(temp);
    }

    _dropDownPanelSize.width = panelWidth + (2*_horizontalPadding);
    _dropDownPanelSize.height = panelHeight;
    [self setFrameSize:_dropDownPanelSize];

    for (int i = 0; i < [options count]; i++) {
        _optionRectsArray[i].size.width = _dropDownPanelSize.width;
        /* Add tracking areas for all the non selected options */
        if (indexOfSelectedOption != i) {
            OptionTrackingRectInfoStruct *tempTrackingAreaInfoStruct = [[OptionTrackingRectInfoStruct alloc] initWithOptionNumber:i];
            NSDictionary *optionTrackingAreaRectDictionary = @{ @"option": tempTrackingAreaInfoStruct};
            NSTrackingArea *optionTrackingArea = [[NSTrackingArea alloc] initWithRect:_optionRectsArray[i] 
                                                                    options: (NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow) 
                                                                    owner:self 
                                                                    userInfo:optionTrackingAreaRectDictionary];
            [self addTrackingArea: optionTrackingArea];
        }
    }

    return self;
}

-(void)mouseEntered:(NSEvent *)e {
    int optionNumber = [[e.trackingArea.userInfo valueForKey:@"option"] optionNumber];
    _optionIsHovered[optionNumber] = 1;
    //NSLog(@"mouse entered!! tracking area: %d", optionNumber);

    [self setNeedsDisplay:YES];
}

-(void)mouseExited:(NSEvent *)e {
    int optionNumber = [[e.trackingArea.userInfo valueForKey:@"option"] optionNumber];
    _optionIsHovered[optionNumber] = 0;
    [self setNeedsDisplay:YES];
    //NSLog(@"mouse exited!!");
}

-(void)positionDropDownPanel:(NSPoint)position {
    [self setFrameOrigin:position];
}

-(void)drawRect:(NSRect)dirtyRect {
    /* Draw Background of Option Selector Control Drop Down Panel */
    CGContextRef drawingContext = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetRGBFillColor(drawingContext, 0.7, 0.7, 0.7, 1.0);
    CGContextFillRect(drawingContext, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height));


    /*
        Draw all the option lines in the panel
    */
    for (int i = 0; i < CFArrayGetCount(_textOptionLines); i++) {
        /* Only draw the option if it is not the selected option */
        if (i != _indexOfSelectedOption) {
            /* Draw the options focus background if it is hovered */
            if (_optionIsHovered[i]) {
                CGContextSetRGBFillColor(drawingContext, 0.8, 0.8, 0.9, 1.0);
                CGContextFillRect(drawingContext, _optionRectsArray[i]);
            }

            /* Draw the text for the selected option */
            CGContextSetTextPosition(drawingContext, _textPositionsOfOptions[i].x, _textPositionsOfOptions[i].y);
            CTLineDraw((CTLineRef) CFArrayGetValueAtIndex(_textOptionLines, (long) i), drawingContext);
        }
    }

    //NSLog(@"drawRect for panel called");
}

-(void)dealloc {
    CFRelease(_textOptionLines);
    free(_textPositionsOfOptions);
    free(_optionRectsArray);
    free(_optionIsHovered);
}

@end