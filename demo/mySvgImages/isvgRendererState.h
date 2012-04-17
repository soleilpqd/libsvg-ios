/* isvgRenderrer: render SVG image into UIImage using CoreGraphics/QuartzCore
 *
 * Copyright © DuongPQ <soleilpqd@gmail.com>
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

#import "svg.h"

typedef struct isvg_render_state {
    CGContextRef context;
    CGMutablePathRef path;
    
    svg_color_t color;
    
    svg_paint_t strokePaint;
    svg_paint_t fillPaint;
    double fillOpacity;
    double strokeOpacity;
	svg_fill_rule_t fileRule;
    
    char *fontFamily;
    double fontSize;
    svg_font_style_t fontStyle;
    unsigned int fontWeight;
    bool fontDirty;
    
    double *dash;
    int numDashes;
    double dashOffset;
    
    double opacity;
    
    unsigned int viewportWidth;
    unsigned int viewportHeight;
    
    int bbox;
    
    svg_text_anchor_t textAnchor;
    
    struct isvg_render_state *next;
    
    CGLineCap lineCap;
    CGLineJoin lineJoin;
    double miterLimit;
    double lineWidth;
} isvg_render_state_t;

svg_status_t isvgRenderStateCreate( isvg_render_state_t **state );
svg_status_t isvgRenderStateDestroy( isvg_render_state_t *state );
isvg_render_state_t *isvgRenderStatePush( isvg_render_state_t *state );
isvg_render_state_t *isvgRenderStatePop( isvg_render_state_t *state );