//
//  DetailViewController.h
//  mySvgImages
//
//  Created by soleilpqd on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UIScrollViewDelegate> {
	IBOutlet UIImageView *_imageView;
	IBOutlet UIScrollView *_scrollView;
}

@property ( nonatomic, retain ) NSString *imageName;

@end
