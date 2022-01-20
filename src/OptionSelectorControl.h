#ifndef __OptionSelectorControl__
#define __OptionSelectorControl__

#include <Cocoa/Cocoa.h>
#include <CoreFoundation/CoreFoundation.h>
#include <QuartzCore/QuartzCore.h>

@class OptionSelectorControlDropDownPanel;

@interface OptionSelectorControl : NSView

@property (strong) NSArray<NSString *> *options;
@property (strong) NSFont *font;


@property (strong) NSObject *selectHandlerObject;


@property int indexOfSelectedOption;
@property CFAttributedStringRef selectedOptionAttributedStringRef;
@property CTLineRef selectedOptionCTLineRef;
@property NSPoint selectedOptionTextDrawPos;

@property id mouseEventMonitor;

@property CGImageRef dropdownArrowImg;
@property BOOL dropDownPanelVisible;
@property OptionSelectorControlDropDownPanel *dropDownPanel;

-(SEL)selectHandlerMethod;
-(void)removeMouseEventMonitor;
-(void)changeSelectedOption:(int)indexOfNewOption withCTLine:(CTLineRef)ctLine;
-(instancetype)initWithFrame:(NSRect)frame options:(NSArray<NSString *> *)options selectHandlerObject:(NSObject *)handler selectHandlerMethod:(SEL)handlerMethod;
-(void)drawRect:(NSRect)dirtyRect;
-(void)resetCursorRects;
//-(void)cursorUpdate:(NSEvent *)e;

@end

#endif /* __OptionSelectorControl__ */
