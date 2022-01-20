#include <metal_stdlib>
using namespace metal;

struct vertexInOut {
    float4 vertPosition [[position]];
    float2 textureCoordinate; /* will be interpolated by the rasterizer */
};

struct Size2D {
    float width;
    float height;
    float aspectRatio;
};

vertex vertexInOut vertexFunction(const device float4* vertexPositionBuffer [[buffer(0)]],
                                  const device float2* textureCoordinateBuffer [[buffer(1)]],
                                  uint vertex_index [[vertex_id]]) {

    
    struct vertexInOut output;
    output.vertPosition = vertexPositionBuffer[vertex_index];
    output.textureCoordinate = textureCoordinateBuffer[vertex_index];
    return output; /* goes to rasterizer */
}

fragment float4 fragmentFunctionName(vertexInOut interpolatedVertex [[stage_in]], texture2d<float> tex [[texture(0)]], sampler aSampler [[sampler(0)]]) {
    return tex.sample(aSampler, interpolatedVertex.textureCoordinate);
}

/* 
    Bicubic interpolation algorithm:
    https://en.wikipedia.org/wiki/Bicubic_interpolation
*/
fragment float4 bicubicInterpolationFragment(device atomic_uint &debugInfo [[buffer(0)]], device float* debugInfoFloats [[buffer(1)]], device int *debugInfoInts [[buffer(2)]], vertexInOut interpolatedVertex [[stage_in]], texture2d<float, access::read> tex [[texture(0)]]) {
    uint texture_width = tex.get_width();
    uint texture_height = tex.get_height();

    /*
        Get the indices of the 16 pixels around the sampling location.
        When the sampling location is at the edge of the texture, the indices of pixels out of image bounds are set to the index of the pixel on the edge of the image.
    */
    float csl = (interpolatedVertex.textureCoordinate[0] * texture_width) - 0.5; /* column sample location */
    float rsl = (interpolatedVertex.textureCoordinate[1] * texture_height) - 0.5; /* row sample location */

    float yn = (rsl >= 0) ? (1.0f - (rsl - floor(rsl))) : 0;
    float xn = (csl >= 0) ? (csl - floor(csl)) : 0;

    uint ri1 = 0;
    uint ri0 = 0;
    uint ri2 = 0;
    uint ri3 = 0;

    if (rsl >= 1.0f && texture_height >= 4 && rsl <= (texture_height - 2)) { /* When all the rows of the 4x4 sampling area are within the image bounds */        
        ri1 = floor(rsl);
        ri0 = floor(ri1 - 0.1f);
        ri2 = floor(rsl + 1.0f);
        ri3 = floor(rsl + 2.0f);
    } else {
        if (rsl < 0) {
            ri1 = 0;
        } else {
            ri1 = floor(rsl);
        }

        if (rsl < 1) {
            ri0 = 0;
        } else {
            ri0 = floor(rsl - 1.0f);
        }

        if (rsl >= (texture_height - 1)) {
            ri2 = texture_height - 1;
        } else if (rsl < 0) {
            ri2 = 0;
        } else {
            ri2 = floor(rsl + 1.0f);
        }

        if (rsl >= (texture_height - 2)) {
            ri3 = texture_height - 1;
        } else if (rsl < 0) {
            ri3 = 1;
        } else {
            ri3 = floor(rsl + 2.0f);
        }
    }

    uint ci1 = 0;
    uint ci0 = 0;
    uint ci2 = 0;
    uint ci3 = 0;

    if (csl >= 1.0f && texture_width >= 4 && csl <= (texture_width - 2)) { /* When all the columns of the 4x4 sampling area are within the image bounds */
        ci1 = floor(csl);
        ci0 = ci1 - 1;
        ci2 = ci1 + 1;
        ci3 = ci1 + 2;
    } else {
        if (csl < 0) {
            ci1 = 0;
        } else {
            ci1 = floor(csl);
        }

        if (csl < 1) {
            ci0 = 0;
        } else {
            ci0 = floor(csl - 1.0f);
        }

        if (csl >= (texture_width - 1)) {
            ci2 = texture_width - 1;
        } else if (csl < 0) {
            ci2 = 0;
        } else {
            ci2 = floor(csl + 1.0f);
        }

        if (csl >= (texture_width - 2)) {
            ci3 = texture_width - 1;
        } else if (csl < 0) {
            ci3 = 1;
        } else {
            ci3 = floor(csl + 2.0f);
        }
    }

    /*
        Get the values of the 4 pixels whose centers form a box around the sampling location
    */
    float4 f11 = tex.read(uint2(ci1, ri1));
    float4 f12 = tex.read(uint2(ci1, ri2));
    float4 f21 = tex.read(uint2(ci2, ri1));
    float4 f22 = tex.read(uint2(ci2, ri2));

    /*
        Get the values of the 12 pixels that surround the 4 pixels above.
        These pixels are used to find the derivatives at each of the four points above.
    */
    float4 f00 = tex.read(uint2(ci0, ri0));
    float4 f01 = tex.read(uint2(ci0, ri1));
    float4 f02 = tex.read(uint2(ci0, ri2));
    float4 f03 = tex.read(uint2(ci0, ri3));
    float4 f10 = tex.read(uint2(ci1, ri0));
    float4 f20 = tex.read(uint2(ci2, ri0));
    float4 f30 = tex.read(uint2(ci3, ri0));
    float4 f13 = tex.read(uint2(ci1, ri3));
    float4 f23 = tex.read(uint2(ci2, ri3));
    float4 f33 = tex.read(uint2(ci3, ri3));
    float4 f31 = tex.read(uint2(ci3, ri1));
    float4 f32 = tex.read(uint2(ci3, ri2));

    /*
        Find the x, y, and xy derivatives of the four pixels surrounding the sample location
        Four pixels * 3 derivatives each = 12 derivatives
    */
    float4 fx11 = (f01 - f21)/2.0;
    float4 fx12 = (f02 - f22)/2.0;  
    float4 fx21 = (f11 - f31)/2.0;    
    float4 fx22 = (f12 - f32)/2.0; 
    float4 fy11 = (f10 - f12)/2.0;    
    float4 fy12 = (f11 - f13)/2.0;    
    float4 fy21 = (f20 - f22)/2.0;    
    float4 fy22 = (f21 - f23)/2.0;
    float4 fxy11 = (((f00 - f20)/2.0) - ((f02 - f22)/2.0))/2.0;   
    float4 fxy12 = (((f01 - f21)/2.0) - ((f03 - f23)/2.0))/2.0;   
    float4 fxy21 = (((f10 - f30)/2.0) - ((f12 - f32)/2.0))/2.0;   
    float4 fxy22 = (((f11 - f31)/2.0) - ((f13 - f33)/2.0))/2.0;

    float4 result = float4(0.0f, 0.0f, 0.0f, 1.0f);
    for (int i = 0; i < 3; i++) {
        /*
            Solve for the 16 unknown coefficients of the bicubic equation
        */
        float4x4 eq1;
        eq1[0][0] = 1;
        eq1[1][0] = 0;
        eq1[2][0] = 0;
        eq1[3][0] = 0;
        eq1[0][1] = 0;
        eq1[1][1] = 0;
        eq1[2][1] = 1;
        eq1[3][1] = 0;
        eq1[0][2] = -3;
        eq1[1][2] = 3;
        eq1[2][2] = -2;
        eq1[3][2] = -1;
        eq1[0][3] = 2;
        eq1[1][3] = -2;
        eq1[2][3] = 1;
        eq1[3][3] = 1;

        float4x4 eq2;
        eq2[0][0] = f12[i];
        eq2[1][0] = f11[i];
        eq2[2][0] = fy12[i];
        eq2[3][0] = fy11[i];
        eq2[0][1] = f22[i];
        eq2[1][1] = f21[i];
        eq2[2][1] = fy22[i];
        eq2[3][1] = fy21[i];
        eq2[0][2] = fx12[i];
        eq2[1][2] = fx11[i];
        eq2[2][2] = fxy12[i];
        eq2[3][2] = fxy11[i];
        eq2[0][3] = fx22[i];
        eq2[1][3] = fx21[i];
        eq2[2][3] = fxy22[i];
        eq2[3][3] = fxy21[i];

        float4x4 eq3;
        eq3[0][0] = 1;
        eq3[1][0] = 0;
        eq3[2][0] = -3;
        eq3[3][0] = 2;
        eq3[0][1] = 0;
        eq3[1][1] = 0;
        eq3[2][1] = 3;
        eq3[3][1] = -2;
        eq3[0][2] = 0;
        eq3[1][2] = 1;
        eq3[2][2] = -2;
        eq3[3][2] = 1;
        eq3[0][3] = 0;
        eq3[1][3] = 0;
        eq3[2][3] = -1;
        eq3[3][3] = 1;

        float4x4 coefficients = eq1*eq2*eq3;

        float yn2 = yn*yn;
        float yn3 = yn2*yn;
        float xn2 = xn*xn;
        float xn3 = xn2*xn;

        float4 xeqn = float4(1.0f, xn, xn2, xn3);
        float4 yeqn = float4(1.0f, yn, yn2, yn3);

        result[i] = dot(xeqn, coefficients*yeqn);
    }
    

    /*
    if (rsl > 100.0f && rsl < 200.0f && csl > 1300.0f && csl < 1400.0f) {

        //return float4(0.2, 0.3, 0.8, 1.0);

        uint printBit = atomic_load_explicit(&debugInfo, memory_order_relaxed);

        if (printBit == 0) {
            uint firstRead = atomic_fetch_add_explicit(&debugInfo, 1, memory_order_relaxed);

            if (firstRead == 0) {
                debugInfoFloats[0] = test;
                debugInfoFloats[1] = test;
                debugInfoFloats[2] = test;
                debugInfoFloats[3] = test;


                debugInfoInts[0] = ri0;
                debugInfoInts[1] = ri1;
                debugInfoInts[2] = ri2;
                debugInfoInts[3] = ri3;

                debugInfoInts[4] = 0;

                debugInfoInts[5] = ci0;
                debugInfoInts[6] = ci1;
                debugInfoInts[7] = ci2;
                debugInfoInts[8] = ci3;
            }
        }
        //debugInfoFloats[0] = yn;
        //debugInfoFloats[1] = xn;
    }
    */

    return result;
}