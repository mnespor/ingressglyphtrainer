//
//  IGTViewController.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/25/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTViewController.h"
#import "IGTDrawableView.h"

@interface IGTViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dots;
@property (weak, nonatomic) IBOutlet IGTDrawableView* drawableView;
@property (weak, nonatomic) IBOutlet UILabel* glyphNameLabel;

@property (strong, nonatomic) NSOperationQueue* bgQueue;
@property (weak, nonatomic) UITouch* drawingTouch;
@property (strong, nonatomic) NSDictionary* glyphs;
@property (strong, nonatomic) NSSet* questionGlyph;
@property (strong, nonatomic) NSMutableSet* answerGlyph;
@property (strong, nonatomic) UIView* lastDot;
@property (strong, nonatomic) UIBezierPath* answerPathSoFar;
@property (strong, nonatomic) UIBezierPath* endOfAnswerPathToTouch;

@property (nonatomic) BOOL canDraw;


- (void)loadGlyphs;
- (UIView*)viewForTouch:(UITouch*)touch event:(UIEvent*)event;
- (void)drawAndFadeGlyph:(NSSet*)glyph;
- (NSString*)nameOfGlyph:(NSSet*)glyph;
- (void)randomizeQuestionGlyph;
- (void)updateAnswerGlyphWithEvent:(UIEvent*)event;

@end

@implementation IGTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bgQueue = [[NSOperationQueue alloc] init];
    self.answerPathSoFar = [UIBezierPath bezierPath];
    self.answerPathSoFar.lineWidth = 16;
    self.answerPathSoFar.lineCapStyle = kCGLineCapRound;
    self.answerPathSoFar.lineJoinStyle = kCGLineJoinRound;
    self.endOfAnswerPathToTouch = [UIBezierPath bezierPath];
    self.endOfAnswerPathToTouch.lineWidth = 16;
    self.endOfAnswerPathToTouch.lineCapStyle = kCGLineCapRound;
    self.endOfAnswerPathToTouch.lineJoinStyle = kCGLineJoinRound;
    
    self.answerGlyph = [NSMutableSet set];
    self.canDraw = YES;
    self.drawableView.drawingColor = [UIColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0];
    
    [self.drawableView.bezierPaths addObjectsFromArray:@[self.answerPathSoFar, self.endOfAnswerPathToTouch]];

    for (UIView* dot in self.dots) {
        dot.layer.cornerRadius = 20.0;
    }
    
    [self loadGlyphs];
    [self randomizeQuestionGlyph];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)drawAndFadeGlyph:(NSSet *)glyph
{
    self.canDraw = NO;
    self.lastDot = nil;
    [self.endOfAnswerPathToTouch removeAllPoints];
    
    UIColor* c = [UIColor yellowColor];
    
    BOOL match = [self.answerGlyph isEqual:self.questionGlyph];
    if (match)
    {
        c = [UIColor greenColor];
    }
    else
    {
        c = [UIColor redColor];
    }
    
    self.glyphNameLabel.text = [self nameOfGlyph:glyph];
    
    self.drawableView.drawingColor = c;
    [self.drawableView setNeedsDisplay];
    
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.7
                     animations:^{
                         weakSelf.drawableView.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         weakSelf.drawableView.alpha = 1.0;
                         weakSelf.canDraw = YES;
                         [weakSelf.answerGlyph removeAllObjects];
                         weakSelf.drawableView.drawingColor = [UIColor colorWithRed:0.5 green:0.8 blue:1.0 alpha:1.0];
                         [weakSelf.answerPathSoFar removeAllPoints];
                         [weakSelf.drawableView setNeedsDisplay];
                         if (match)
                         {
                             [weakSelf randomizeQuestionGlyph];
                         }
                         else
                         {
                             weakSelf.glyphNameLabel.text = [weakSelf nameOfGlyph:weakSelf.questionGlyph];
                         }
                     }];
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

- (NSString*)nameOfGlyph:(NSSet *)glyph
{
    NSString* result;
    for (NSString* k in [self.glyphs allKeys]) {
        if ([self.glyphs[k] isEqualToSet:glyph])
        {
            result = k;
            break;
        }
    }
    
    return result;
}

- (void)randomizeQuestionGlyph
{
    // TODO
}

- (void)setQuestionGlyph:(NSSet *)questionGlyph
{
    self.glyphNameLabel.textColor = [UIColor orangeColor];
    self.glyphNameLabel.text = [self nameOfGlyph:questionGlyph];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canDraw)
        return;
    
    if (self.drawingTouch == nil)
    {
        self.drawingTouch = ([touches anyObject]);
        [self updateAnswerGlyphWithEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:self.drawingTouch])
    {
        [self drawAndFadeGlyph:self.answerGlyph];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canDraw)
        return;

    if ([touches containsObject:self.drawingTouch])
    {
        [self updateAnswerGlyphWithEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Change the answer glyph's color and present its name. If it's the same as
    // the question glyph, green; else, red. Then fade, remove all points from
    // the existing bezier path, and choose a new question glyph.
    if ([touches containsObject:self.drawingTouch])
    {
        [self drawAndFadeGlyph:self.answerGlyph];
    }
}

- (void)updateAnswerGlyphWithEvent:(UIEvent *)event
{
    UIView* potentialDot = [self viewForTouch:self.drawingTouch event:event];
    if (potentialDot != nil && potentialDot != self.lastDot)
    {
        if (self.lastDot != nil)
        {
            [self.answerGlyph addObject:[NSSet setWithObjects:
                                         [NSNumber numberWithInt:self.lastDot.tag],
                                         [NSNumber numberWithInt:potentialDot.tag],
                                         nil]];
        }
        else
        {
            [self.answerPathSoFar moveToPoint:potentialDot.center];
        }
        
        self.lastDot = potentialDot;
        potentialDot.backgroundColor = [UIColor whiteColor];
        potentialDot.alpha = 1.0;
        [UIView animateWithDuration:0.4
                         animations:^{
                             potentialDot.alpha = 0.0;
                         }
                         completion:^(BOOL finished) {
                             potentialDot.backgroundColor = [UIColor clearColor];
                             potentialDot.alpha = 1.0;
                         }];
        [self.answerPathSoFar addLineToPoint:self.lastDot.center];
        NSLog(@"Path: %@", self.answerPathSoFar);
    }
    
    if (self.lastDot != nil)
    {
        [self.endOfAnswerPathToTouch removeAllPoints];
        [self.endOfAnswerPathToTouch moveToPoint:self.lastDot.center];
        [self.endOfAnswerPathToTouch addLineToPoint:[self.drawingTouch locationInView:self.drawableView]];
    }
    
    [self.drawableView setNeedsDisplay];
}

// Returns the dot being touched, or nil if the touch is between dots
- (UIView*)viewForTouch:(UITouch *)touch event:(UIEvent*)event
{
    UIView* result = nil;
    for (UIView* dotView in self.dots) {
        result = [dotView hitTest:[touch locationInView:dotView] withEvent:event];
        if (result != nil)
        {
            return result;
        }
    }
    
    return result;
}

@end
