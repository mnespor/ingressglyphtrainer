//
//  IGTViewController.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/25/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTViewController.h"
#import "IGTDotView.h"
#import "IGTDrawableImageView.h"

@interface IGTViewController ()

@property (strong, nonatomic) IBOutletCollection(IGTDotView) NSArray *dots;
@property (weak, nonatomic) IBOutlet IGTDrawableImageView* imageView;

@property (strong, nonatomic) NSOperationQueue* bgQueue;
@property (weak, nonatomic) UITouch* drawingTouch;
@property (strong, nonatomic) NSDictionary* glyphs;
@property (strong, nonatomic) NSDictionary* activeGlyph;

- (void)loadGlyphs;
- (IGTDotView*)viewForTouch:(UITouch*)touch;
- (void)drawAndFadeGlyph:(NSSet*)glyph;

@end

@implementation IGTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.bgQueue = [[NSOperationQueue alloc] init];
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
        NSDictionary* orderedGlyphs = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"glpyhs" ofType:@"plist"]];
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
- (IGTDotView*)viewForTouch:(UITouch *)touch
{
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches containsObject:self.drawingTouch])
    {
        self.activeGlyph = nil;
        [self.imageView clear];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
}

@end
