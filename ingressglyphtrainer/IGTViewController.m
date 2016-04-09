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
#import "IGTGlyphDataHelpers.h"
#include <stdlib.h>

@interface IGTViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dots;
@property (weak, nonatomic) IBOutlet IGTDrawableView* drawableView;
@property (weak, nonatomic) IBOutlet UILabel* glyphNameLabel;

@property (strong, nonatomic) NSOperationQueue* bgQueue;
@property (weak, nonatomic) UITouch* drawingTouch;
@property (strong, nonatomic) NSDictionary* glyphs;
@property (strong, nonatomic) NSMutableDictionary* userGlyphs;
@property (strong, nonatomic) NSSet* questionGlyph;
@property (strong, nonatomic) NSMutableSet* answerGlyph;
@property (strong, nonatomic) UIView* lastDot;
@property (strong, nonatomic) UIBezierPath* answerPathSoFar;
@property (strong, nonatomic) UIBezierPath* endOfAnswerPathToTouch;

@property (strong, nonatomic) NSMutableArray* cardsLeftInThisSession;

@property (nonatomic) BOOL canDraw;

- (NSMutableArray*)dequeueSession;

- (void)loadGlyphs;
- (UIView*)viewForTouch:(UITouch*)touch event:(UIEvent*)event;
- (void)drawAndFadeGlyph:(NSSet*)glyph withDuration:(CGFloat)duration;
- (NSString*)nameOfGlyph:(NSSet*)glyph;
- (void)randomizeQuestionGlyph;
- (void)updateAnswerGlyphWithEvent:(UIEvent*)event;

- (IBAction)showMe:(id)sender;

@end

@implementation IGTViewController

- (NSArray*)allEnabledGlyphs {
    return [[self.glyphs allKeys] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
        return ![IGTGlyphDataHelpers glyphIsDisabled:glyphName];
    }]];
}

- (NSMutableArray*)dequeueSession
{
    NSInteger sessionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"sessionNumber"];
    NSArray* enabledGlyphs = [self allEnabledGlyphs];
    
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:enabledGlyphs.count];
    [result addObjectsFromArray:[enabledGlyphs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
        return [IGTGlyphDataHelpers boxNumberForGlyphNamed:glyphName] == 1;
    }]]];
    
    if (result.count < 5)
    {
        NSMutableArray* boxZero = [[enabledGlyphs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
            return [IGTGlyphDataHelpers boxNumberForGlyphNamed:glyphName] == 0;
        }]] mutableCopy];
        
        while (result.count < 5 && boxZero.count > 0)
        {
            int index = arc4random_uniform((uint32_t)boxZero.count);
            [result addObject:boxZero[index]];
            [IGTGlyphDataHelpers setBoxNumber:1 forGlyphNamed:boxZero[index]];
            [boxZero removeObjectAtIndex:index];
        }
    }
    
    if (sessionNumber % 2 == 0)
    {
        [result addObjectsFromArray:[enabledGlyphs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
            return [IGTGlyphDataHelpers boxNumberForGlyphNamed:glyphName] == 2;
        }]]];
    }
    
    if (sessionNumber % 3 == 0)
    {
        [result addObjectsFromArray:[enabledGlyphs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
            return [IGTGlyphDataHelpers boxNumberForGlyphNamed:glyphName] == 3;
        }]]];
    }
    
    if (sessionNumber % 7 == 0)
    {
        [result addObjectsFromArray:[enabledGlyphs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
            return [IGTGlyphDataHelpers boxNumberForGlyphNamed:glyphName] == 4;
        }]]];
    }
    
    if (sessionNumber % 15 == 0)
    {
        // then may whatever god you believe in have mercy on your soul
        [result addObjectsFromArray:[enabledGlyphs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* glyphName, NSDictionary *bindings) {
            return [IGTGlyphDataHelpers boxNumberForGlyphNamed:glyphName] == 5;
        }]]];
    }
    
    sessionNumber = (sessionNumber % 15) + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:sessionNumber forKey:@"sessionNumber"];
    
    return result;
}

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
    
    if ([[NSUserDefaults standardUserDefaults] integerForKey:@"sessionNumber"] == 0)
    {
        [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"sessionNumber"];
        [IGTGlyphDataHelpers setDisabledState:YES forGlyphNamed:@"ENLIGHTENED / ENLIGHTENMENT (TYPE B)"];
        [IGTGlyphDataHelpers setDisabledState:YES forGlyphNamed:@"RESIST / RESISTANCE (TYPE B)"];
        [IGTGlyphDataHelpers setDisabledState:YES forGlyphNamed:@"SHAPER / COLLECTIVE + BEING / HUMAN"];
    }
    
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

- (void)drawAndFadeGlyph:(NSSet *)glyph withDuration:(CGFloat)duration
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
        [IGTGlyphDataHelpers setBoxNumber:[IGTGlyphDataHelpers boxNumberForGlyphNamed:self.glyphNameLabel.text] + 1 forGlyphNamed:self.glyphNameLabel.text];
        c = [UIColor greenColor];
    }
    else
    {
        [IGTGlyphDataHelpers setBoxNumber:0 forGlyphNamed:self.glyphNameLabel.text];
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
    [UIView animateWithDuration:duration
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
    if (self.cardsLeftInThisSession.count == 0)
    {
        self.cardsLeftInThisSession = [self dequeueSession];
    }
    
    if (self.cardsLeftInThisSession.count == 0)
    {
        // uh oh. Super set I guess.
        self.cardsLeftInThisSession = [[self allEnabledGlyphs] mutableCopy];
    }
    NSString* name = [self.cardsLeftInThisSession firstObject];
    [self.cardsLeftInThisSession removeObjectAtIndex:0];
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
        [self drawAndFadeGlyph:self.answerGlyph withDuration:0.4];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.canDraw)
        return;

    if (self.drawingTouch == nil)
    {
        self.drawingTouch = [touches anyObject];
    }
    
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
        [self drawAndFadeGlyph:self.answerGlyph withDuration:0.4];
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
                                         [NSNumber numberWithInteger:self.lastDot.tag],
                                         [NSNumber numberWithInteger:potentialDot.tag],
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
    [self drawAndFadeGlyph:self.questionGlyph withDuration:0.8];
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
        dest.glyphs = self.glyphs;
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

- (IBAction)cancelGlyphList:(UIStoryboardSegue*)segue
{
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
