//
//  BNRLine.m
//  TouchTracker
//
//  Created by Peter Molnar on 17/05/2015.
//  Copyright (c) 2015 Peter Molnar. All rights reserved.
//

#import "BNRLine.h"

@implementation BNRLine


-(UIColor *)setupColorFromAngle
{
    CGFloat angle = [self pointPairToBearingDegrees:self.begin secondPoint:self.end];
    UIColor *calculatedColor;
    
    if (angle>0.0) {
        float angleAsFloat = angle / 360.0;
        calculatedColor = [[UIColor alloc] initWithHue:angleAsFloat saturation:.9 brightness:1.0 alpha:1.0];
    } else {
        calculatedColor = [UIColor redColor];
    }
    
    return calculatedColor;
}


#pragma mark - Helper functions

- (CGFloat) pointPairToBearingDegrees:(CGPoint)startingPoint secondPoint:(CGPoint) endingPoint
{
    CGPoint originPoint = CGPointMake(endingPoint.x - startingPoint.x, endingPoint.y - startingPoint.y); // get origin point to origin by subtracting end from start
    float bearingRadians = atan2f(originPoint.y, originPoint.x); // get bearing in radians
    float bearingDegrees = bearingRadians * (180.0 / M_PI); // convert to degrees
    bearingDegrees = (bearingDegrees > 0.0 ? bearingDegrees : (360.0 + bearingDegrees)); // correct discontinuity
    return bearingDegrees;
}

@end
