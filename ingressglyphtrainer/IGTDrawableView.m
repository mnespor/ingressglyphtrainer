//
//  IGTDrawableImageView.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/26/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTDrawableView.h"

typedef enum
{
    IGTDotPositionTop = 1,
    IGTDotPositionOutsideUpperRight = 2,
    IGTDotPositionOutsideLowerRight = 3,
    IGTDotPositionBottom = 4,
    IGTDotPositionOutsideLowerLeft = 5,
    IGTDotPositionOutsideUpperLeft = 6,
    IGTDotPositionInsideUpperLeft = 7,
    IGTDotPositionInsideUpperRight = 8,
    IGTDotPositionInsideLowerRight = 9,
    IGTDotPositionInsideLowerLeft = 10,
    IGTDotPositionCenter = 11
} IGTDotPosition;

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

- (CGPoint)pointForDotNumbered:(int)dot
{
    switch (dot) {
        case IGTDotPositionTop:
            return CGPointMake(self.bounds.size.width / 2.0, 0.0);
            break;
        case IGTDotPositionOutsideUpperRight:
            return CGPointMake(self.bounds.size.width, self.bounds.size.height / 4.0);
            break;
        case IGTDotPositionOutsideLowerRight:
            return CGPointMake(self.bounds.size.width, self.bounds.size.height * 3.0 / 4.0);
            break;
        case IGTDotPositionBottom:
            return CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height);
            break;
        case IGTDotPositionOutsideLowerLeft:
            return CGPointMake(0.0, self.bounds.size.height * 3.0 / 4.0);
            break;
        case IGTDotPositionOutsideUpperLeft:
            return CGPointMake(0.0, self.bounds.size.height / 4.0);
            break;
        case IGTDotPositionInsideUpperLeft:
            return CGPointMake(self.bounds.size.width / 4.0, self.bounds.size.height * 3.0 / 8.0);
            break;
        case IGTDotPositionInsideUpperRight:
            return CGPointMake(self.bounds.size.width * 3.0 / 4.0, self.bounds.size.height * 3.0 / 8.0);
            break;
        case IGTDotPositionInsideLowerRight:
            return CGPointMake(self.bounds.size.width * 3.0 / 4.0, self.bounds.size.height * 5.0 / 8.0);
            break;
        case IGTDotPositionInsideLowerLeft:
            return CGPointMake(self.bounds.size.width / 4.0, self.bounds.size.height * 5.0 / 8.0);
            break;
        case IGTDotPositionCenter:
            return CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.width / 2.0);
            break;
        default:
            NSLog(@"Unexpected dot index %d; returning CGPointZero", dot);
            return CGPointZero;
    }
}

- (void)setGlyph:(NSSet *)glyph
{
    [self.bezierPaths removeAllObjects];
    for (NSSet* pair in glyph) {
        NSArray* orderedPair = [pair allObjects];
        UIBezierPath* segment = [UIBezierPath bezierPath];
        segment.lineWidth = 1;
        [segment moveToPoint:[self pointForDotNumbered:[orderedPair[0] intValue]]];
        [segment addLineToPoint:[self pointForDotNumbered:[orderedPair[1] intValue]]];
        [self.bezierPaths addObject:segment];
    }
    
    [self setNeedsDisplay];
}

@end
