//
//  IGTGlyphTableViewCell.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 8/8/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTGlyphTableViewCell.h"
#import "IGTGlyphDataHelpers.h"

@interface IGTGlyphTableViewCell ()

- (void)onOffTapped:(id)sender;

@end

@implementation IGTGlyphTableViewCell

- (void)awakeFromNib
{
    [self.onOffButton addTarget:self action:@selector(onOffTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)onOffTapped:(id)sender
{
    self.onOffButton.selected = !self.onOffButton.selected;
    [IGTGlyphDataHelpers setDisabledState:!self.onOffButton.selected forGlyphNamed:self.glyphNameLabel.text];
}

- (void)setGlyph:(NSSet *)glyph name:(NSString*)name
{
    self->_glyph = glyph;
    self.glyphNameLabel.text = name;
    BOOL glyphDisabled = [IGTGlyphDataHelpers glyphIsDisabled:name];
    self.onOffButton.selected = !glyphDisabled;
    self.glyphPreview.drawingColor = [UIColor whiteColor];
    [self.glyphPreview setGlyph:glyph];
}

@end
