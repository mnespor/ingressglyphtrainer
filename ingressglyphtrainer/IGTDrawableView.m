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
        self->_bezierPaths = [NSMutableSet set];
    }
    return self;
}

- (void)awakeFromNib
{
    self->_bezierPaths = [NSMutableSet set];
}

- (void)drawRect:(CGRect)rect
{
    if (self.drawingColor == nil)
    {
        self.drawingColor = [UIColor greenColor];
    }
    
    [self.drawingColor setStroke];
    
    for (UIBezierPath* path in self.bezierPaths)
    {
        [path stroke];
    }
}


@end
