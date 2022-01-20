
#ifndef Hello_Window_MetalView_Delegate_h
#define Hello_Window_MetalView_Delegate_h

#include <Foundation/Foundation.h>
#include <MetalKit/MetalKit.h>
#include <Metal/Metal.h>

@interface MetalView_Delegate : NSObject <MTKViewDelegate>

@property (weak) MTKView *theView;
@property id<MTLCommandQueue> commandQueue;
@property MTLRenderPassDescriptor* renderPassDescriptor;
@property id<MTLRenderPipelineState> renderPipelineState;
@property id<MTLSamplerState> samplerState;
@property id<MTLTexture> imageToDraw;

@property int interpolationMethod;

@property MTLRenderPipelineDescriptor* pipelineDescriptor;
@property id<MTLLibrary> library;
//@property id<MTLRenderPipelineState> renderPipelineState;

- (instancetype)initWithMetalView:(MTKView *)aMetalView;

/* Method to change image interpolation method of view */
- (void)changeInterpolationMethod:(NSNumber *)method;
- (void)setNewImage:(NSURL *)imageToOpen;


/* MTKViewDelegate required protocol methods */
- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size;
- (void)updateVertexPositionsForNewViewSize:(CGSize)newViewSize;
- (void)drawInMTKView:(MTKView *)view;
-(void)dealloc;
@end

#endif /* Hello_Window_MetalView_Delegate_h */
