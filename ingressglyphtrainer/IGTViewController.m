//
//  IGTViewController.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/25/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTViewController.h"
#import "IGTDrawableView.h"
#import "IGTGlyphListTableViewController.h"

@interface IGTViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dots;
@property (weak, nonatomic) IBOutlet IGTDrawableView* drawableView;
@property (weak, nonatomic) IBOutlet UILabel* glyphNameLabel;

@property (strong, nonatomic) NSOperationQueue* bgQueue;
@property (weak, nonatomic) UITouch* drawingTouch;
@property (strong, nonatomic) NSDictionary* glyphs;
@property (strong, nonatomic) NSArray* sortedGlyphNames;
@property (strong, nonatomic) NSMutableDictionary* userGlyphs;
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

- (IBAction)showMe:(id)sender;

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

    if (glyph != self.answerGlyph)
    {
        [self.answerPathSoFar removeAllPoints];

        BOOL setOrigin = NO;
        for (NSSet* pair in glyph) {
            for (NSNumber* point in pair)
            {
                if (!setOrigin)
                {
                    [self.answerPathSoFar moveToPoint:[self.view viewWithTag:[point integerValue]].center];
                    setOrigin = YES;
                }
                else
                {
                    [self.answerPathSoFar addLineToPoint:[self.view viewWithTag:[point integerValue]].center];
                    setOrigin = NO;
                }
            }
        }
    }
    
    UIColor* c;
    
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
    if (NO && self.glyphNameLabel.text.length == 0)
    {
        UIAlertView* learningView = [[UIAlertView alloc] initWithTitle:@"Whoa!"
                                                               message:@"Which glyph was that?"
                                                              delegate:self
                                                     cancelButtonTitle:@"Don't save"
                                                     otherButtonTitles:@"Save", nil];
        learningView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [learningView show];
        return;
    }
    
    self.drawableView.drawingColor = c;
    [self.drawableView setNeedsDisplay];
    
    __weak __typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.8
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

        weakSelf.userGlyphs = [orderedGlyphs mutableCopy];
        weakSelf.glyphs = [unorderedGlyphs copy];
        weakSelf.sortedGlyphNames = [[unorderedGlyphs allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 caseInsensitiveCompare:obj2];
            }];

        [weakSelf randomizeQuestionGlyph];
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
    int idx = arc4random_uniform((int)self.glyphs.count);
    NSArray* allKeys = [self.glyphs allKeys];
    NSString* name = allKeys[idx];
    self.questionGlyph = self.glyphs[name];
}

- (void)setQuestionGlyph:(NSSet *)questionGlyph
{
    self.glyphNameLabel.text = [self nameOfGlyph:questionGlyph];
    self->_questionGlyph = questionGlyph;
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

#pragma mark - IBActions

- (IBAction)showMe:(id)sender
{
    [self drawAndFadeGlyph:self.questionGlyph];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
    {
        NSString* glyphPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        glyphPath = [glyphPath stringByAppendingPathComponent:@"glyphs.plist"];
        NSString* name = [alertView textFieldAtIndex:0].text;
        if (name.length > 0)
        {
            NSMutableArray* pairs = [NSMutableArray arrayWithCapacity:self.answerGlyph.count];
            for (NSSet* pair in self.answerGlyph) {
                [pairs addObject:[pair allObjects]];
            }
            [self.userGlyphs setObject:pairs forKey:name];
            [self.userGlyphs writeToFile:glyphPath atomically:NO];
        }
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue.destinationViewController topViewController] isKindOfClass:[IGTGlyphListTableViewController class]])
    {
        IGTGlyphListTableViewController* dest = (IGTGlyphListTableViewController*)[segue.destinationViewController topViewController];
        dest.search = nil;
        dest.glyphNames = self.sortedGlyphNames;
    }
}

- (IBAction)unwindFromGlyphListToGlyphCanvas:(UIStoryboardSegue*)segue
{
    IGTGlyphListTableViewController* tvc = (IGTGlyphListTableViewController*)segue.sourceViewController;
    if ([tvc.tableView indexPathsForSelectedRows].count > 0)
    {
        NSIndexPath* idx = [[tvc.tableView indexPathsForSelectedRows] firstObject];
        self.questionGlyph = self.glyphs[tvc.filteredNames[idx.row]];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
