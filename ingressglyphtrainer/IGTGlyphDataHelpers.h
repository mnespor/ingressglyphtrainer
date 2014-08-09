//
//  IGTGlyphDataHelpers.h
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 8/8/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IGTGlyphDataHelpers : NSObject

+ (BOOL)glyphIsDisabled:(NSString*)glyphName;
+ (void)setDisabledState:(BOOL)disabled forGlyphNamed:(NSString*)name;

+ (int)boxNumberForGlyphNamed:(NSString*)name;
+ (void)setBoxNumber:(int)boxNumber forGlyphNamed:(NSString*)name;

@end
