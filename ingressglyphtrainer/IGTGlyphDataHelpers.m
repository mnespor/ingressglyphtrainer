//
//  IGTGlyphDataHelpers.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 8/8/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTGlyphDataHelpers.h"

@implementation IGTGlyphDataHelpers

+ (BOOL)glyphIsDisabled:(NSString*)glyphName
{
    NSDictionary* glyphData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:glyphName];
    return [glyphData[@"disabled"] boolValue];
}

+ (void)setDisabledState:(BOOL)disabled forGlyphNamed:(NSString*)name
{
    NSMutableDictionary* mutableGlyphData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:name] mutableCopy];
    if (mutableGlyphData == nil)
    {
        mutableGlyphData = [NSMutableDictionary dictionary];
    }
    
    mutableGlyphData[@"disabled"] = [NSNumber numberWithBool:disabled];
    [[NSUserDefaults standardUserDefaults] setObject:mutableGlyphData forKey:name];
}

+ (int)boxNumberForGlyphNamed:(NSString*)name
{
    NSDictionary* glyphData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:name];
    return [glyphData[@"boxNumber"] intValue];
}

+ (void)setBoxNumber:(int)boxNumber forGlyphNamed:(NSString*)name
{
    NSMutableDictionary* mutableGlyphData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:name] mutableCopy];
    if (mutableGlyphData == nil)
    {
        mutableGlyphData = [NSMutableDictionary dictionary];
    }
    
    mutableGlyphData[@"boxNumber"] = [NSNumber numberWithInt:boxNumber];
    [[NSUserDefaults standardUserDefaults] setObject:mutableGlyphData forKey:name];
}

@end
