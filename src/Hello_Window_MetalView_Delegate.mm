#include "Hello_Window_MetalView_Delegate.h"

@implementation MetalView_Delegate {
    float *vertexPositions;
    float *textureMappingCoordinates;
}

- (instancetype)initWithMetalView:(MTKView *)aMetalView{
    if (self = [super init]) {
        _theView = aMetalView;
        _interpolationMethod = 0;

        /* Create a MTLCommandQueue */
        id<MTLCommandQueue> aCommandQueue = [[aMetalView device] newCommandQueue];

        /* Create a MTLRenderPipelineDescriptor */
        //MTLRenderPipelineDescriptor* pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        _pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        [_pipelineDescriptor setLabel:@"RenderPipelineDescriptor1"];
        
        NSBundle *appBundle = [NSBundle mainBundle];
        if (appBundle == nil) {
            NSLog(@"Error. Could not get reference to app bundle. Exiting...");
            exit(1);
        }
        NSURL *pathToApp = [appBundle URLForResource:@"Hello_Window_Shaders" withExtension:@"metallib"];
        if (pathToApp == nil) {
            NSLog(@"Error. Could not get path to metal library. Exiting...");
            exit(1);
        }

        NSError *shaderProgramLibraryError;
        _library = [[aMetalView device] newLibraryWithURL:pathToApp error:&shaderProgramLibraryError];

        if (shaderProgramLibraryError == nil) {
            NSLog(@"Successfully loaded metal shader library");
        } else {
            NSLog(@"Error. Could not load metal shader library. Exiting...");
            NSLog(@"%@", [shaderProgramLibraryError domain]);
            NSLog(@"%@", [shaderProgramLibraryError localizedDescription]);
            exit(1);
            return nil;
        }

        id<MTLFunction> vertexFunction = [_library newFunctionWithName:@"vertexFunction"];
        id<MTLFunction> fragmentFunction = [_library newFunctionWithName:@"fragmentFunctionName"];
        [_pipelineDescriptor setVertexFunction: vertexFunction]; 
        [_pipelineDescriptor setFragmentFunction: fragmentFunction];
        [[_pipelineDescriptor colorAttachments][0] setPixelFormat:MTLPixelFormatBGRA8Unorm];
                
        //CAMetalLayer * caLayer = (CAMetalLayer *) [aMetalView layer];
        //NSLog(@"metal view colorpixelformat: %lu", [aMetalView colorPixelFormat]);
        //NSLog(@"metal view cametallayer pixel formate: %lu", [caLayer pixelFormat]);
        //caLayer.wantsExtendedDynamicRangeContent = YES;

        vertexPositions = (float *) malloc(sizeof(float)*24);
        textureMappingCoordinates = (float *) malloc(sizeof(float)*12);
        textureMappingCoordinates[0] = 0.0; textureMappingCoordinates[1] = 1.0;
        textureMappingCoordinates[2] = 1.0; textureMappingCoordinates[3] = 1.0;
        textureMappingCoordinates[4] = 0.0; textureMappingCoordinates[5] = 0.0;
        textureMappingCoordinates[6] = 0.0; textureMappingCoordinates[7] = 0.0;
        textureMappingCoordinates[8] = 1.0; textureMappingCoordinates[9] = 0.0;
        textureMappingCoordinates[10] = 1.0; textureMappingCoordinates[11] = 1.0;

        /* Create MTLRenderPipelineState object from the MTLRenderPipelineDescriptor */
        NSError *pipelineStateError;
        id<MTLRenderPipelineState> renderPipelineState = [[aMetalView device] newRenderPipelineStateWithDescriptor:_pipelineDescriptor error:&pipelineStateError];
        /* https://developer.apple.com/documentation/metal/mtldevice/1433369-newrenderpipelinestatewithdescri?language=objc */
        if (pipelineStateError == nil) {
            NSLog(@"Successfully created MTLRenderPipelineState");
        } else {
            NSLog(@"Erorr creating MTLRenderPipelineState");
        }

        /* Create a Sampler Descriptor */
        MTLSamplerDescriptor *sampleDesc = [[MTLSamplerDescriptor alloc] init];
        [sampleDesc setSAddressMode:MTLSamplerAddressModeClampToEdge];
        [sampleDesc setLodMinClamp:0.0];
        [sampleDesc setMinFilter:MTLSamplerMinMagFilterNearest]; // MTLSamplerMinMagFilterLinear
        [sampleDesc setMagFilter:MTLSamplerMinMagFilterNearest];
        [sampleDesc setMipFilter:MTLSamplerMipFilterNotMipmapped];
        //[sampleDesc setMaxAnisotropy:1]; // 1 to 16
        //[sampleDesc setLodMaxClamp:FLT_MAX];
        [sampleDesc setLodAverage:NO];

        /* Create a Sampler State Object from the Sampler Descriptor */
        id<MTLSamplerState> samplerState = [[aMetalView device] newSamplerStateWithDescriptor:sampleDesc];
        [self setSamplerState:samplerState];
        
        NSDictionary *texture_loader_options = @{
            MTKTextureLoaderOptionSRGB: @NO
        };
        MTKTextureLoader* textLoader = [[MTKTextureLoader alloc] initWithDevice:[aMetalView device]];
        NSError *textureLoadingError;
        NSURL *pathToPlaceholderImage = [appBundle URLForResource:@"open_image_placeholder" withExtension:@"png"];
        id<MTLTexture> aTexture = [textLoader newTextureWithContentsOfURL:pathToPlaceholderImage options:texture_loader_options error:&textureLoadingError];
        [self setImageToDraw:aTexture];
        
        if(textureLoadingError == nil) {
            NSLog(@"Successfully loaded placeholder image");
        } else {
            NSLog(@"%@", [textureLoadingError domain]);
            NSLog(@"%@", [textureLoadingError localizedDescription]);
            NSLog(@"Error loading image");
            exit(1);
        }

        /* Set the instance variables */
        [self setImageToDraw:aTexture];
        [self setCommandQueue:aCommandQueue];
        [self setRenderPipelineState:renderPipelineState];
    }
    return self;
}

- (void)changeInterpolationMethod:(NSNumber *)method {
    int methodInt = [method intValue];
    _interpolationMethod = methodInt;
    //NSLog(@"Change Interpolation Method: %d", methodInt);

    /* Create a Sampler Descriptor */
    MTLSamplerDescriptor *sampleDesc = [[MTLSamplerDescriptor alloc] init];
    [sampleDesc setSAddressMode:MTLSamplerAddressModeClampToEdge];
    [sampleDesc setLodMinClamp:0.0];
    [sampleDesc setMipFilter:MTLSamplerMipFilterNotMipmapped];
    //[sampleDesc setMaxAnisotropy:1]; // 1 to 16
    //[sampleDesc setLodMaxClamp:FLT_MAX];
    [sampleDesc setLodAverage:NO];

    /* Nearest Neighbor Interpolation */
    if (methodInt == 0) {
        [sampleDesc setMinFilter:MTLSamplerMinMagFilterNearest];
        [sampleDesc setMagFilter:MTLSamplerMinMagFilterNearest];

        id<MTLFunction> vertexFunction = [_library newFunctionWithName:@"vertexFunction"];
        id<MTLFunction> fragmentFunction = [_library newFunctionWithName:@"fragmentFunctionName"];
        [_pipelineDescriptor setVertexFunction: vertexFunction]; 
        [_pipelineDescriptor setFragmentFunction: fragmentFunction];
        [[_pipelineDescriptor colorAttachments][0] setPixelFormat:MTLPixelFormatBGRA8Unorm];

        /* Create MTLRenderPipelineState object from the MTLRenderPipelineDescriptor */
        NSError *pipelineStateError;
        id<MTLRenderPipelineState> renderPipelineState = [[_theView device] newRenderPipelineStateWithDescriptor:_pipelineDescriptor error:&pipelineStateError];
        if (pipelineStateError == nil) {
            NSLog(@"Successfully created MTLRenderPipelineState");
        } else {
            //NSLog(@"Error creating MTLRenderPipelineState");
        }
        [self setRenderPipelineState:renderPipelineState];
    }
    /* Bilinear Interpolation */
    else if (methodInt == 1) {
        [sampleDesc setMinFilter:MTLSamplerMinMagFilterLinear];
        [sampleDesc setMagFilter:MTLSamplerMinMagFilterLinear];

        id<MTLFunction> vertexFunction = [_library newFunctionWithName:@"vertexFunction"];
        id<MTLFunction> fragmentFunction = [_library newFunctionWithName:@"fragmentFunctionName"];
        [_pipelineDescriptor setVertexFunction: vertexFunction]; 
        [_pipelineDescriptor setFragmentFunction: fragmentFunction];
        [[_pipelineDescriptor colorAttachments][0] setPixelFormat:MTLPixelFormatBGRA8Unorm];

        /* Create MTLRenderPipelineState object from the MTLRenderPipelineDescriptor */
        NSError *pipelineStateError;
        id<MTLRenderPipelineState> renderPipelineState = [[_theView device] newRenderPipelineStateWithDescriptor:_pipelineDescriptor error:&pipelineStateError];
        if (pipelineStateError == nil) {
            NSLog(@"Successfully created MTLRenderPipelineState");
        } else {
            //NSLog(@"Error creating MTLRenderPipelineState");
        }
        [self setRenderPipelineState:renderPipelineState];
    }
    /* Bicubic Interpolation TODO */
    else if (methodInt == 2) {
        id<MTLFunction> vertexFunction = [_library newFunctionWithName:@"vertexFunction"];
        id<MTLFunction> fragmentFunction = [_library newFunctionWithName:@"bicubicInterpolationFragment"];
        [_pipelineDescriptor setVertexFunction: vertexFunction]; 
        [_pipelineDescriptor setFragmentFunction: fragmentFunction];
        [[_pipelineDescriptor colorAttachments][0] setPixelFormat:MTLPixelFormatBGRA8Unorm];

        /* Create MTLRenderPipelineState object from the MTLRenderPipelineDescriptor */
        NSError *pipelineStateError;
        id<MTLRenderPipelineState> renderPipelineState = [[_theView device] newRenderPipelineStateWithDescriptor:_pipelineDescriptor error:&pipelineStateError];
        if (pipelineStateError == nil) {
            NSLog(@"Successfully created MTLRenderPipelineState");
        } else {
            //NSLog(@"Error creating MTLRenderPipelineState");
        }
        [self setRenderPipelineState:renderPipelineState];
    }

    /* Create a Sampler State Object from the Sampler Descriptor */
    id<MTLSamplerState> samplerState = [[_theView device] newSamplerStateWithDescriptor:sampleDesc];
    [self setSamplerState:samplerState];
    [_theView setNeedsDisplay:YES];
    return;
}

- (void)setNewImage:(NSURL *)imageToOpen {

    if (imageToOpen == nil) {
        return;
    }

    NSDictionary *texture_loader_options = @{
        MTKTextureLoaderOptionSRGB: @NO
    };
    MTKTextureLoader* textLoader = [[MTKTextureLoader alloc] initWithDevice:[_theView device]];
    NSError *textureLoadingError;
    id<MTLTexture> aTexture = [textLoader newTextureWithContentsOfURL:imageToOpen options:texture_loader_options error:&textureLoadingError];
    [self setImageToDraw:aTexture];
    
    if(textureLoadingError == nil) {
        NSLog(@"Successfully loaded image");
    } else {
        NSLog(@"%@", [textureLoadingError domain]);
        NSLog(@"%@", [textureLoadingError localizedDescription]);
        NSLog(@"Error loading image");
        return;
    }

    /* Set the instance variables */
    [self setImageToDraw:aTexture];
    [_theView setNeedsDisplay:YES];
}

- (void)updateVertexPositionsForNewViewSize:(CGSize)newViewSize {

    if (_imageToDraw == nil) {
        NSLog(@"View's image is null. Exiting updateVertexPositionsForNewViewSize");
        return;
    }

    float imageWidth = 1.0f * _imageToDraw.width;
    float imageHeight = 1.0f * _imageToDraw.height;

    float imageAspectRatio = (1.0f * imageWidth)/imageHeight;
    float metalViewAspectRatio = (1.0f * newViewSize.width)/newViewSize.height;
    //NSLog(@"imageWidth: %f, imageHeight: %f", imageWidth, imageHeight);
    //NSLog(@"w: %f, h: %f", view.frame.size.width, view.frame.size.height);
    //NSLog(@"imageAspectRatio: %f, metalViewAspectRatio: %f,", imageAspectRatio, metalViewAspectRatio);

    // When the width of the image takes up the width of the view, but there is a gap above and below the image to the edge of the view
    if (imageAspectRatio > metalViewAspectRatio) {
        //NSLog(@"case: imageAspectRatio > metalViewAspectRatio");
        float imageTopEdgeY = ((2.0f / imageAspectRatio) * metalViewAspectRatio) / 2.0f;

        //NSLog(@"bottom y: %f", (-1)*imageTopEdgeY);

        // Triangle 1
        // bottom left
        vertexPositions[0] = -1.0f; vertexPositions[1] = (-1)*imageTopEdgeY; vertexPositions[2] = 0; vertexPositions[3] = 1;
        // bottom right
        vertexPositions[4] = 1.0f; vertexPositions[5] = (-1)*imageTopEdgeY; vertexPositions[6] = 0; vertexPositions[7] = 1;
        // top left
        vertexPositions[8] = -1.0f; vertexPositions[9] = imageTopEdgeY; vertexPositions[10] = 0; vertexPositions[11] = 1;

        // Triangle 2
        // top left
        vertexPositions[12] = -1.0f; vertexPositions[13] = imageTopEdgeY; vertexPositions[14] = 0; vertexPositions[15] = 1;
        // top right
        vertexPositions[16] = 1.0f; vertexPositions[17] = imageTopEdgeY; vertexPositions[18] = 0; vertexPositions[19] = 1;
        // bottom right
        vertexPositions[20] = 1.0f; vertexPositions[21] = (-1)*imageTopEdgeY; vertexPositions[22] = 0; vertexPositions[23] = 1;
    } else {
        float imageRightEdgeX = ((2.0f * imageAspectRatio) / metalViewAspectRatio) / 2.0f;

        // Triangle 1
        // bottom left
        vertexPositions[0] = (-1)*imageRightEdgeX; vertexPositions[1] = -1.0f; vertexPositions[2] = 0; vertexPositions[3] = 1;
        // bottom right
        vertexPositions[4] = imageRightEdgeX; vertexPositions[5] = -1.0f; vertexPositions[6] = 0; vertexPositions[7] = 1;
        // top left
        vertexPositions[8] = (-1)*imageRightEdgeX; vertexPositions[9] = 1.0f; vertexPositions[10] = 0; vertexPositions[11] = 1;

        // Triangle 2
        // top left
        vertexPositions[12] = (-1)*imageRightEdgeX; vertexPositions[13] = 1.0f; vertexPositions[14] = 0; vertexPositions[15] = 1;
        // top right
        vertexPositions[16] = imageRightEdgeX; vertexPositions[17] = 1.0f; vertexPositions[18] = 0; vertexPositions[19] = 1;
        // bottom right
        vertexPositions[20] = imageRightEdgeX; vertexPositions[21] = -1.0f; vertexPositions[22] = 0; vertexPositions[23] = 1;
    }
} 

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

- (void)drawInMTKView:(MTKView *)view {

    if ([view currentDrawable] == nil) {
        NSLog(@"The MTKView's currentDrawable is nil, returning.");
        return;
    }

    @autoreleasepool {

    _renderPassDescriptor = [view currentRenderPassDescriptor];

    [self updateVertexPositionsForNewViewSize:view.frame.size];

    /* Create a Command Buffer */
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    /* Create Command Encoder */
    id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];

    /* Set the render pipeline state object of the commandEncoder */
    [commandEncoder setRenderPipelineState:_renderPipelineState];

    /* Create buffers for vertex position and color data */
    id<MTLBuffer> vertexPositionsBuffer = [[view device] newBufferWithBytes:vertexPositions length:sizeof(float)*24 options:MTLResourceStorageModeShared];
    id<MTLBuffer> textureCoordinatesBuffer = [[view device] newBufferWithBytes:textureMappingCoordinates length:sizeof(float)*12 options:MTLResourceStorageModeShared];

    int *debugInfo = (int *) malloc(sizeof(int)*10);
    debugInfo[0] = 0;
    debugInfo[1] = 7;
    debugInfo[2] = 15;
    id<MTLBuffer> debugInfoBuffer = [[view device] newBufferWithBytes:debugInfo length:sizeof(int)*10 options:MTLResourceStorageModeShared];
    [commandEncoder setFragmentBuffer:debugInfoBuffer offset:0 atIndex:0];

    float *debugInfoFloats = (float *) malloc(sizeof(float)*10);
    debugInfoFloats[0] = 1.45;
    id<MTLBuffer> debugInfoBufferFloats = [[view device] newBufferWithBytes:debugInfo length:sizeof(float)*10 options:MTLResourceStorageModeShared];
    [commandEncoder setFragmentBuffer:debugInfoBufferFloats offset:0 atIndex:1];

    int *debugInfoInts = (int *) malloc(sizeof(int)*10);
    debugInfoInts[0] = 0;
    id<MTLBuffer> debugInfoBufferInts = [[view device] newBufferWithBytes:debugInfoInts length:sizeof(int)*10 options:MTLResourceStorageModeShared];
    [commandEncoder setFragmentBuffer:debugInfoBufferInts offset:0 atIndex:2];

    /* Set vertex buffers for the render commandEncoder using the previously created buffers */
    [commandEncoder setVertexBuffer:vertexPositionsBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:textureCoordinatesBuffer offset:0 atIndex:1];
    //[commandEncoder setVertexBuffer:vertexColorsBuffer offset:0 atIndex:1];

    /* Specify a texture reference to be encoded into the buffer and set it as a texture that the fragment function can access */
    [commandEncoder setFragmentTexture:_imageToDraw atIndex:0];

    /* Set a sampler for the command buffer */
    [commandEncoder setFragmentSamplerState:_samplerState atIndex:0];


    /* Specify the drawing method for the rasterizer to use and the number of vertices */
    [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

    /* Done adding drawing commands to command buffer */
    [commandEncoder endEncoding];

    /* Must call before commit: method below */
    if ([view currentDrawable] != nil) {
        [commandBuffer presentDrawable:[view currentDrawable]];
        //[commandBuffer presentDrawable:[(CAMetalLayer *)[view layer] nextDrawable]];
        //NSLog(@"drawable size: %f, h: %f", view.currentDrawable.layer.drawableSize.width, view.currentDrawable.layer.drawableSize.height);
    } else {
        NSLog(@"currentDrawable is nil");
    }

    /* Commit the buffer to be sent to the gpu */
    [commandBuffer commit];


    [commandBuffer waitUntilCompleted];

    if ([commandBuffer status] == MTLCommandBufferStatusCompleted) {
        /*
        NSLog(@"Command Buffer Completed");
        int *debugInfoResult = (int *)[debugInfoBuffer contents];
        float *debugInfoResultFloats = (float *)[debugInfoBufferFloats contents];
        NSLog(@"debugInfoResult: %d, %d, %d, %d, %d", debugInfoResult[0], debugInfoResult[1], debugInfoResult[2], debugInfoResult[3], debugInfoResult[6]);
        NSLog(@"debugInfoFloats: %f, %f, %f, %f", debugInfoResultFloats[0], debugInfoResultFloats[1], debugInfoResultFloats[2], debugInfoResultFloats[3]);
        int *debugInfoBufferIntsResult = (int *)[debugInfoBufferInts contents];
        NSLog(@"debugInfoBufferInts: %d, %d, %d, %d, %d, %d, %d, %d, %d", debugInfoBufferIntsResult[0], debugInfoBufferIntsResult[1], debugInfoBufferIntsResult[2], debugInfoBufferIntsResult[3], debugInfoBufferIntsResult[4], debugInfoBufferIntsResult[5], debugInfoBufferIntsResult[6], debugInfoBufferIntsResult[7], debugInfoBufferIntsResult[8]);
        */
    }
    free(debugInfo);
    free(debugInfoFloats);
    free(debugInfoInts);
    }
}

-(void)dealloc {
    NSLog(@"dealloc MetalView_Delegate");
    free(vertexPositions);
    free(textureMappingCoordinates);
}

@end