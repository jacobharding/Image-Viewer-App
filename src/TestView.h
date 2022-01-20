#ifndef __TestView__
#define __TestView__

#include <Cocoa/Cocoa.h>
#include <QuartzCore/QuartzCore.h>

@interface TestView : NSView

@property (strong) NSArray* options;

-(instancetype)initWithFrame:(NSRect)frame;
-(void)drawRect:(NSRect)dirtyRect;

@end

#endif /* __TestView__ */
