//
//  IGTGlyphListTableViewController.m
//  ingressglyphtrainer
//
//  Created by Matthew Nespor on 7/26/14.
//  Copyright (c) 2014 Matthew Nespor. All rights reserved.
//

#import "IGTGlyphListTableViewController.h"

@interface IGTGlyphListTableViewController ()

@property (strong, nonatomic) NSOperationQueue* searchQueue;

@end

@implementation IGTGlyphListTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setGlyphNames:(NSArray *)glyphNames
{
    self->_glyphNames = glyphNames;
    self.filteredNames = glyphNames;
    [(UITableView*)self.view reloadData];
}

- (void)setSearch:(NSString *)search
{
    self->_search = [search copy];
    if (self.searchQueue == nil)
    {
        self.searchQueue = [[NSOperationQueue alloc] init];
    }
    
    if (search.length > 0)
    {
        __weak __typeof(self) weakSelf = self;
        [self.searchQueue addOperationWithBlock:^{
            weakSelf.filteredNames = [weakSelf.glyphNames filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString* evaluatedObject, NSDictionary *bindings) {
                return [[evaluatedObject lowercaseString] rangeOfString:search].location != NSNotFound;
            }]];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [weakSelf.tableView reloadData];
            }];
        }];
    }
    else
    {
        self.filteredNames = self.glyphNames;
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredNames.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GlyphCell" forIndexPath:indexPath];
    ((UILabel*)[cell viewWithTag:1]).text = self.filteredNames[indexPath.row];
    return cell;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.search = [searchText lowercaseString];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.search = nil;
}

@end
