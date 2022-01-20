#ifndef __OptionSelectorControlDropDownPanel__
#define __OptionSelectorControlDropDownPanel__

#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <QuartzCore/QuartzCore.h>



@class OptionSelectorControl;

@interface OptionSelectorControlDropDownPanel : NSView


@property (weak) OptionSelectorControl* optionSelectorControl;
@property NSPoint *textPositionsOfOptions;
@property CFMutableArrayRef textOptionLines;
@property NSFont *font;
@property int indexOfSelectedOption;
@property float horizontalPadding;
@property float optionVerticalPadding;
@property int numberOfOptions;

/* This is equal to the width of the option whose text width is largest plus 2 times the horizontal padding */
@property NSSize dropDownPanelSize;

/* Array of rects (origin and size) of the option boxes, these change as the user 
changes which option is selected */
@property NSRect *optionRectsArray;

/* array of 1s and 0s for each option, where one means the option is hovered and 0 means it is not 
used to determine if a focus background should be drawn for the option */
@property int* optionIsHovered;


-(void)recalculateOptionRects;
-(instancetype)initWithFrame:(NSRect)frame optionSelectorControl:(OptionSelectorControl *)optionSelectorControl options:(NSArray<NSString *> *)options indexOfSelectedOption:(int)indexOfSelectedOption;
-(void)positionDropDownPanel:(NSPoint)position;
-(void)drawRect:(NSRect)dirtyRect;


/*
@property (strong) NSArray<NSString *> *options;
@property (strong) NSFont *font;

@property CFAttributedStringRef selectedOptionAttributedStringRef;
@property CTLineRef selectedOptionCTLineRef;
@property NSPoint selectedOptionTextDrawPos;

@property BOOL dropDownPanelVisible;

-(instancetype)initWithFrame:(NSRect)frame options:(NSArray<NSString *> *)options;
-(void)resetCursorRects;
*/

@end

#endif /* __OptionSelectorControlDropDownPanel__ */
