//
//  MasterViewController.h
//  mySvgImages
//
//  Created by soleilpqd on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController {
	NSArray *_imageNames;
    NSArray *_samplesNames;
}

@property (strong, nonatomic) DetailViewController *detailViewController;

@end
