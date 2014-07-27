//
//  IGTGlyphListTableViewController.h
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/26/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IGTGlyphListTableViewController : UITableViewController <UISearchBarDelegate>

@property (strong, nonatomic) NSArray* glyphNames;
@property (strong, nonatomic) NSArray* filteredNames;
@property (copy, nonatomic) NSString* search;

@end
