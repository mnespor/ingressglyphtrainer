//
//  IGTDrawableImageView.h
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/26/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import <UIKit/UIKit.h>

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

@interface IGTDrawableView : UIView

@property (readonly) NSMutableSet* bezierPaths;
@property (strong, nonatomic) UIColor* drawingColor;

// works if this view is square. If not, well...
- (CGPoint)pointForDotNumbered:(int)dot;
- (void)setGlyph:(NSSet*)glyph;

@end
