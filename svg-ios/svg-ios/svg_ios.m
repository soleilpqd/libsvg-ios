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

#import "svg_ios.h"
#import "isvgRenderer.h"

@implementation svg_ios

+ ( NSString* )about {
    return @"LibSVG-iOS";
}

@end

#pragma mark - UIImage additional

@implementation UIImage (isvg)

+ ( UIImage* )imageWithContentsOfSVGFile:(NSString *)path withTransform:( CGAffineTransform )transform {
    if (![[ NSFileManager defaultManager ] fileExistsAtPath:path ])
        NSAssert( FALSE, @"ISVG file not found/invalid input path: %@", path );
	svg_t *svg;
	if ( !isvgNewRenderEngineWithFile( &svg, [ path UTF8String ])) return nil;
    svg_length_t w, h;
    svg_get_size( svg, &w, &h );
	double a, b;
	isvgRenderLengthToPixel( NULL, &w, &a );
	isvgRenderLengthToPixel( NULL, &h, &b );
	isvg_render_t *render;
	if ( isvgRenderNew( &render ) != SVG_STATUS_SUCCESS ) return nil;
    CGSize imgSize = CGSizeMake( a, b );
    CGSize destSize = CGSizeApplyAffineTransform( imgSize, transform );
    CGFloat scale = fmax( destSize.width / imgSize.width, destSize.height / imgSize.height );
    UIGraphicsBeginImageContextWithOptions( destSize, NO, scale );
    render->state->context = UIGraphicsGetCurrentContext();
	render->viewportWidth = a;
	render->viewportHeight = b;
    CGContextConcatCTM( render->state->context, transform );
	BOOL renderRes = isvgRenderSvg( svg, render );
    UIImage *res = nil;
    if ( renderRes ) res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	svg_destroy( svg );
	return res;
}

+ ( UIImage* )imageWithContentsOfSVGFile:(NSString *)path withScale:( CGFloat )scale {
    CGAffineTransform transform = CGAffineTransformMakeScale( scale, scale );
    return [ self imageWithContentsOfSVGFile:path withTransform:transform ];
}

+ ( UIImage* )imageWithContentsOfSVGFile:(NSString *)path {
    return [ self imageWithContentsOfSVGFile:path withTransform:CGAffineTransformIdentity ];
}

@end

#pragma mark - NSData additional

@implementation NSData (isvg)

- ( UIImage* )svgImagewithTransform:( CGAffineTransform )transform {
	svg_t *svg;
	if ( !isvgNewRenderEngineWithData( &svg, self.bytes, self.length )) return nil;
    svg_length_t w, h;
    svg_get_size( svg, &w, &h );
	double a, b;
	isvgRenderLengthToPixel( NULL, &w, &a );
	isvgRenderLengthToPixel( NULL, &h, &b );
	isvg_render_t *render;
	if ( isvgRenderNew( &render ) != SVG_STATUS_SUCCESS ) return nil;
    CGSize imgSize = CGSizeMake( a, b );
    CGSize destSize = CGSizeApplyAffineTransform( imgSize, transform );
    CGFloat scale = fmax( destSize.width / imgSize.width, destSize.height / imgSize.height );
    UIGraphicsBeginImageContextWithOptions( destSize, NO, scale );
    render->state->context = UIGraphicsGetCurrentContext();
	render->viewportWidth = a;
	render->viewportHeight = b;
    CGContextConcatCTM( render->state->context, transform );
	BOOL renderRes = isvgRenderSvg( svg, render );
    UIImage *res = nil;
    if ( renderRes ) res = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	svg_destroy( svg );
	return res;
}

- ( UIImage* )imageWithScale:( CGFloat )scale {
    CGAffineTransform transform = CGAffineTransformMakeScale( scale, scale );
    return [ self svgImagewithTransform:transform ];
}

- ( UIImage* )svgImage {
    return [ self svgImagewithTransform:CGAffineTransformIdentity ];
}

@end