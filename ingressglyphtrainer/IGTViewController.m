//
//  IGTViewController.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/25/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTViewController.h"
#import "IGTDotView.h"
#import "IGTDrawableView.h"

@interface IGTViewController ()

@property (strong, nonatomic) IBOutletCollection(IGTDotView) NSArray *dots;
@property (weak, nonatomic) IBOutlet IGTDrawableView* drawableView;

@property (strong, nonatomic) NSOperationQueue* bgQueue;
@property (weak, nonatomic) UITouch* drawingTouch;
@property (strong, nonatomic) NSDictionary* glyphs;
@property (strong, nonatomic) NSDictionary* questionGlyph;
@property (strong, nonatomic) NSMutableSet* answerGlpyh;
@property (strong, nonatomic) IGTDotView* lastDot;

- (void)loadGlyphs;
- (IGTDotView*)viewForTouch:(UITouch*)touch event:(UIEvent*)event;
- (void)drawAndFadeGlyph:(NSSet*)glyph;

@end

@implementation IGTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bgQueue = [[NSOperationQueue alloc] init];
    self.drawableView.bezierPath = [UIBezierPath bezierPath];
    self.drawableView.bezierPath.lineWidth = 16;
    self.drawableView.bezierPath.lineCapStyle = kCGLineCapRound;
    self.drawableView.bezierPath.lineJoinStyle = kCGLineJoinRound;
    [self loadGlyphs];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)loadGlyphs
{
    // A glyph is a name and an unordered collection of unordered vertex pairs.
    // Because NSSet can't be serialized to a plist, the collections of vertex pairs are stored
    // in arrays on disk and converted to sets on read.
    
    __weak __typeof(self) weakSelf = self;
    [self.bgQueue addOperationWithBlock:^{
        NSDictionary* orderedGlyphs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glyphs" ofType:@"plist"]];
        NSMutableDictionary* unorderedGlyphs = [NSMutableDictionary dictionaryWithCapacity:orderedGlyphs.count];
        for (NSString* glyphName in [orderedGlyphs allKeys]) {
            NSArray* pairs = orderedGlyphs[glyphName];
            NSMutableSet* unorderedPairs = [NSMutableSet setWithCapacity:pairs.count];
            for (NSArray* pair in pairs) {
                [unorderedPairs addObject:[NSSet setWithArray:pair]];
            }
            
            unorderedGlyphs[glyphName] = [unorderedPairs copy];
        }
        
        weakSelf.glyphs = [unorderedGlyphs copy];
    }];
}

// Returns the dot being touched, or nil if the touch is between dots
- (IGTDotView*)viewForTouch:(UITouch *)touch event:(UIEvent*)event
{
    IGTDotView* result = nil;
    for (IGTDotView* dotView in self.dots) {
        result = (IGTDotView*)[dotView hitTest:[touch locationInView:dotView] withEvent:event];
        if (result != nil)
        {
            return result;
        }
    }
    
    return result;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.drawingTouch == nil)
    {
        self.drawingTouch = ([touches anyObject]);
        IGTDotView* potentialDot = [self viewForTouch:self.drawingTouch event:event];
        if (potentialDot != nil && potentialDot != self.lastDot)
        {
            if (self.lastDot != nil)
            {
                [self.answerGlpyh addObject:[NSSet setWithObjects:
                                             [NSNumber numberWithInt:self.lastDot.tag],
                                             [NSNumber numberWithInt:potentialDot.tag],
                                             nil]];
            }
            else
            {
                [self.drawableView.bezierPath moveToPoint:potentialDot.center];
            }
            
            self.lastDot = potentialDot;
            [self.drawableView.bezierPath addLineToPoint:self.lastDot.center];
            NSLog(@"Path: %@", self.drawableView.bezierPath);
        }
        
        //        [self.drawableView.bezierPath moveToPoint:[self.drawingTouch locationInView:self.drawableView]];
        [self.drawableView setNeedsDisplay];

    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:self.drawingTouch])
    {
        self.answerGlpyh = [NSMutableSet set];
        self.lastDot = nil;
        [self.drawableView.bezierPath removeAllPoints];
        [self.drawableView setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // probably do this asynchronously
    
    if ([touches containsObject:self.drawingTouch])
    {
        IGTDotView* potentialDot = [self viewForTouch:self.drawingTouch event:event];
        if (potentialDot != nil && potentialDot != self.lastDot)
        {
            if (self.lastDot != nil)
            {
                [self.answerGlpyh addObject:[NSSet setWithObjects:
                                             [NSNumber numberWithInt:self.lastDot.tag],
                                             [NSNumber numberWithInt:potentialDot.tag],
                                             nil]];
            }
            else
            {
                [self.drawableView.bezierPath moveToPoint:potentialDot.center];
            }
            
            self.lastDot = potentialDot;
            [self.drawableView.bezierPath addLineToPoint:self.lastDot.center];
            NSLog(@"Path: %@", self.drawableView.bezierPath);
        }
        
//        [self.drawableView.bezierPath moveToPoint:[self.drawingTouch locationInView:self.drawableView]];
        [self.drawableView setNeedsDisplay];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Change the answer glyph's color and present its name. If it's the same as
    // the question glyph, green; else, red. Then fade, remove all points from
    // the existing bezier path, and choose a new question glyph.
    if ([touches containsObject:self.drawingTouch])
    {
        self.lastDot = nil;
        self.answerGlpyh = nil;
        [self.drawableView.bezierPath removeAllPoints];
        [self.drawableView setNeedsDisplay];
    }
}

@end
