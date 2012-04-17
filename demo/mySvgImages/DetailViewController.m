//
//  DetailViewController.m
//  mySvgImages
//
//  Created by soleilpqd on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "svg_ios.h"

@interface DetailViewController ()
- (void)configureView;
@end

@implementation DetailViewController

@synthesize imageName = _imageName;

- ( void )setImageName:(NSString *)imageName {
	_imageName = [ imageName retain ];
	self.title = _imageName.lastPathComponent;
}

- ( UIView* )viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return _imageView;
}

- (void)dealloc
{
	[ _imageName release ];
	[ _imageView release ];
	[ _scrollView release ];
    [super dealloc];
}

#pragma mark - Managing the detail item

- (void)configureView
{
	if ( _imageView.image != nil ) {
		_imageView.frame = CGRectMake( 0, 0, _imageView.image.size.width, _imageView.image.size.height );
	} else {
		_imageView.frame = _scrollView.bounds;
	}
	_scrollView.contentSize = _imageView.bounds.size;
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
	_scrollView.zoomScale = 1.0;
	_imageView.image = [ svg_ios imageWithContentsOfSVGFile:_imageName ];
	[self configureView];
//    NSLog( @"%@", [ svg_ios about ]);
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
	return YES;
}

- ( void )willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[ self configureView ];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"Detail", @"Detail");
    }
    return self;
}
							
@end
