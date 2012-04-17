/* libsvg-ios: render SVG image into UIImage using CoreGraphics
 *
 * Copyright © DuongPQ <soleilpqd@gmail.com> from RunSystem
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 * Based on libsvg-cairo - Render SVG documents using the cairo library
 * Libsvg-cairo's author: Carl D. Worth <cworth@isi.edu>
 *
 */

#import <Foundation/Foundation.h>

@interface svg_ios : NSObject {
    
}

+ ( UIImage* )imageWithContentsOfSVGFile:(NSString *)path withTransform:( CGAffineTransform )transform;
+ ( UIImage* )imageWithContentsOfSVGFile:(NSString *)path withScale:( CGFloat )scale;
+ ( UIImage* )imageWithContentsOfSVGFile:(NSString *)path;
+ ( UIImage* )imageWithSVGData:(NSData *)data withTransform:( CGAffineTransform )transform;
+ ( UIImage* )imageWithSVGData:(NSData *)data withScale:( CGFloat )scale;
+ ( UIImage* )imageWithSVGData:(NSData *)data;

@end