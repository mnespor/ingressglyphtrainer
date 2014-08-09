//
//  IGTGlyphTableViewCell.h
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 8/8/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IGTDrawableView.h"

@interface IGTGlyphTableViewCell : UITableViewCell
{
    NSSet* _glyph;
}

@property (weak, nonatomic) IBOutlet UIButton* onOffButton;
@property (weak, nonatomic) IBOutlet UILabel* glyphNameLabel;
@property (weak, nonatomic) IBOutlet IGTDrawableView* glyphPreview;

- (void)setGlyph:(NSSet *)glyph name:(NSString*)name;

@end
