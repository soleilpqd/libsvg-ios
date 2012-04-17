//
//  MasterViewController.m
//  mySvgImages
//
//  Created by soleilpqd on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"
#import "svg_ios.h"
#import "DetailViewController.h"

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Master", @"Master");
    }
    return self;
}
							
- (void)dealloc
{
	[_detailViewController release];
	[ _imageNames release ];
    [ _samplesNames release ];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	_imageNames = [[[[ NSBundle mainBundle ] pathsForResourcesOfType:@"svg"
                                                         inDirectory:@"images" ] sortedArrayUsingSelector:@selector( localizedCaseInsensitiveCompare: )] retain ];
    _samplesNames = [[[[ NSBundle mainBundle ] pathsForResourcesOfType:@"svg"
                                                           inDirectory:@"samples" ] sortedArrayUsingSelector:@selector( localizedCaseInsensitiveCompare: )] retain ];
    
    UIAlertView *alert = [[ UIAlertView alloc ] initWithTitle:@"Images sources" message:@"W3C samples: SVG files from W3C's SVG 1.1 specification.\nGG Images: somes images found from Google Images (I can't remember source), just for testing; they may have copyright so plz use for personal purpose." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil ];
    [ alert show ];
    [ alert release ];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ( section ) {
        case 0:
            return _samplesNames.count;
            break;
        case 1:
            return _imageNames.count;
            break;
    }
	return 0;
}

- ( NSString* )tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ( section ) {
        case 0:
            return @"W3C samples";
            break;
        case 1:
            return @"GG Images";
            break;
    }
    return nil;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

	// Configure the cell.
    switch ( indexPath.section ) {
        case 0:
            cell.textLabel.text = [[ _samplesNames objectAtIndex:indexPath.row ] lastPathComponent ];
            break;
        case 1:
            cell.textLabel.text = [[ _imageNames objectAtIndex:indexPath.row ] lastPathComponent ];
            break;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.detailViewController) {
        self.detailViewController = [[[DetailViewController alloc] initWithNibName:@"DetailViewController" bundle:nil] autorelease];
    }
    switch ( indexPath.section ) {
        case 0:
            self.detailViewController.imageName = [ _samplesNames objectAtIndex:indexPath.row ];
            break;
        case 1:
            self.detailViewController.imageName = [ _imageNames objectAtIndex:indexPath.row ];
            break;
    }
	
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

@end
