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

#import <CoreFoundation/CoreFoundation.h>
#import "isvgRendererState.h"

typedef struct isvg_render {
    isvg_render_state_t *state;
    
    unsigned int viewportWidth;
    unsigned int viewportHeight;
    
//    bool isStroke;
} isvg_render_t;

// C-style functions
// Use to render SVG directly in current context
// See imageWithContentsOfSVGFile source code below to know how to prepare the context

/*
 Render SVG into current context
 svg: svg render engine
 render: render drawing
 */
bool isvgRenderSvg(svg_t *svg, isvg_render_t *render);
/*
 Create SVG render engine from file
 svg: pointer to store the render engine
 filePath: UTF8 CString presents file path
 */
bool isvgNewRenderEngineWithFile( svg_t **svg, const char *filePath );
/*
 Create SVG render engine from buffer
 svg: pointer to store the render engine
 data: pointer to data
 length: number of bytes of data
 */
bool isvgNewRenderEngineWithData( svg_t **svg, const void *data, size_t length );
/*
 Some related utility functions
 */
svg_status_t isvgRenderNew(isvg_render_t **render);
svg_status_t isvgRenderDestroy( isvg_render_t *render );
svg_status_t isvgRenderLengthToPixel( isvg_render_t *render, svg_length_t *length, double *pixel );