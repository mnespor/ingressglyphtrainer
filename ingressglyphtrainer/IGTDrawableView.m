//
//  IGTDrawableImageView.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/26/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTDrawableView.h"

@implementation IGTDrawableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    if (self.drawingColor == nil)
    {
        self.drawingColor = [UIColor greenColor];
    }
    
    [self.drawingColor setStroke];
    [self.bezierPath stroke];
}


@end
