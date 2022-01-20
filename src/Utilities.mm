#include "Utilities.h"

@implementation Utilities

+(void)printNSRect:(NSRect)rect {
    NSLog(@"\nRect:\n\t x: %f\n\t y: %f\n\t width: %f\n\t height: %f ", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+(void)printNSPoint:(NSPoint)point {
       NSLog(@"\nPoint:\n\t x: %f\n\t y: %f\n\t", point.x, point.y);
}

+(void)printBOOL:(BOOL)b {
    if (b == 0) {
        NSLog(@"\nBool: NO");
    } else {
        NSLog(@"\nBool: YES");
    }
}

@end