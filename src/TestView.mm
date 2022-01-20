#include "TestView.h"

@interface TestLayer : CALayer
-(BOOL)masksToBounds;
@end

@implementation TestLayer
-(BOOL)masksToBounds {
        NSLog(@"masksToBounds");
    return NO;
}
@end

@implementation TestView

-(instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];

    NSLog(@"THis was called");

    if (self) {
        [self setWantsLayer:YES];
        TestLayer* test1 = [[TestLayer alloc] init];
        [self setLayer:test1];
    }

    return self;
}

/*
-(void)setWantsDefaultClipping:(BOOL)wantsDefaultClipping {
    // Let the view draw outside of its parent view
    return NO;
}
*/

-(BOOL)wantsDefaultClipping {
    // Let the view draw outside of its parent view
    return NO;
}

-(void)drawRect:(NSRect)dirtyRect {
    CGContextRef drawingContext = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetRGBFillColor(drawingContext, 0.6, 0.9, 0.8, 1.0);
    CGContextFillRect(drawingContext, CGRectMake(0, 0, 100, 200));

    NSLog(@"w: %f, h: %f", self.visibleRect.size.width, self.visibleRect.size.height);
}

@end