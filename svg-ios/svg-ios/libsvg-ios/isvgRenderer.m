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

#import "isvgRenderer.h"

#define DPI_IPHONE_3    163.0
#define DPI_IPHONE_4    326.0
#define DPI_IPAD        132.0
#define DPI_IPAD_NEW    264.0

#define LOG_ENABLED 0

#if LOG_ENABLED
#define myLog( s, ... ) printf( s"\n", ##__VA_ARGS__ )
#else
#define myLog( s, ... ) {}
#endif

static float dpi;

#pragma mark - Pre-define

static svg_status_t isvgBeginGroup(void *closure, double opacity);
static svg_status_t isvgBeginElement(void *closure);
static svg_status_t isvgEndElement(void *closure);
static svg_status_t isvgEndGroup(void *closure, double opacity);
static svg_status_t isvgMoveTo(void *closure, double x, double y);
static svg_status_t isvgLineTo(void *closure, double x, double y);
static svg_status_t isvgCurveTo(void *closure,
                                double x1, double y1,
                                double x2, double y2,
                                double x3, double y3);
static svg_status_t isvgQuadraticCurveTo(void *closure,
                                         double x1, double y1,
                                         double x2, double y2);
void isvgAddArcSegment( void *closure,
                       double xc, double yc,
                       double th0, double th1, double rx, double ry,
                       double x_axis_rotation);
static svg_status_t isvgClosePath(void *closure);
static svg_status_t isvgSetColor(void *closure, const svg_color_t *color);
static svg_status_t isvgSetFillOpacity(void *closure, double fill_opacity);
static svg_status_t isvgSetFillPaint(void *closure, const svg_paint_t *paint);
static svg_status_t isvgSetFillRule(void *closure, svg_fill_rule_t fill_rule);
static svg_status_t isvgSetFontFamily(void *closure, const char *family);
static svg_status_t isvgSetFontSize(void *closure, double size);
static svg_status_t isvgSetFontStyle(void *closure, svg_font_style_t font_style);
static svg_status_t isvgSetFontWeight(void *closure, unsigned int font_weight);
static svg_status_t isvgSetOpacity(void *closure, double opacity);
static svg_status_t isvgSetStrokeDashArray(void *closure, double *dash_array, int num_dashes);
static svg_status_t isvgSetStrokeDashOffset(void *closure, svg_length_t *offset);
static svg_status_t isvgSetStrokeLineCap(void *closure, svg_stroke_line_cap_t line_cap);
static svg_status_t isvgSetStrokeLineJoin(void *closure, svg_stroke_line_join_t line_join);
static svg_status_t isvgSetStrokeMiterLimit(void *closure, double limit);
static svg_status_t isvgSetStrokeOpacity(void *closure, double stroke_opacity);
static svg_status_t isvgSetStrokePaint(void *closure, const svg_paint_t *paint);
static svg_status_t isvgSetStrokeWidth(void *closure, svg_length_t *width);
static svg_status_t isvgSetTextAnchor(void *closure, svg_text_anchor_t text_anchor);
static svg_status_t isvgTransform(void *closure,
                                  double a, double b,
                                  double c, double d,
                                  double e, double f);
static svg_status_t isvgApplyViewBox(void *closure,
                                     svg_view_box_t view_box,
                                     svg_length_t *width,
                                     svg_length_t *height);
static svg_status_t isvgSetViewportDimension(void *closure,
                                             svg_length_t *width,
                                             svg_length_t *height);
static svg_status_t isvgRenderLine(void *closure,
                                   svg_length_t *x1,
                                   svg_length_t *y1,
                                   svg_length_t *x2,
                                   svg_length_t *y2);
static void _isvgMaskForStrokeGradient( isvg_render_t *render );
static bool _isvgIntersection2PointsWithRect( CGRect bounds, CGPoint point1, CGPoint point2, CGPoint *intersect1, CGPoint *intersect2 );
static double _isvg2PointsDistance( CGPoint point1, CGPoint point2 );
static bool _isvgExpandedPoint( CGPoint point1, CGPoint point2, CGPoint *exPoint, double distance );
static void _isvgCreateGradientBrush( svg_gradient_t *svgGradient, int totalNumLocs, bool reverse, CGGradientRef *gradient );
static void _isvgRenderGradient( isvg_render_t *render, bool isStroking );
static svg_status_t isvgRenderPath(void *closure);
static svg_status_t isvgRenderEllipse(void *closure,
                                      svg_length_t *cx,
                                      svg_length_t *cy,
                                      svg_length_t *rx,
                                      svg_length_t *ry);
static svg_status_t isvgRenderRect(void *closure,
                                   svg_length_t *x,
                                   svg_length_t *y,
                                   svg_length_t *width,
                                   svg_length_t *height,
                                   svg_length_t *rx, // not implemented
                                   svg_length_t *ry);
static svg_status_t isvgRenderText(void *closure,
                                   svg_length_t *x,
                                   svg_length_t *y,
                                   const char   *utf8);
static svg_status_t isvgRenderImage(void		 *closure,
                                    unsigned char	*data,
                                    unsigned int	 data_width,
                                    unsigned int	 data_height,
                                    svg_length_t	 *x,
                                    svg_length_t	 *y,
                                    svg_length_t	 *width,
                                    svg_length_t	 *height);
static UIImage *_isvgRenderCImage(unsigned char *data, unsigned int data_width, unsigned int data_height);

static svg_status_t isvgRenderPushState( isvg_render_t *render );
static svg_status_t isvgRenderPopState( isvg_render_t *render );
static svg_render_engine_t ISVG_RENDER_ENGINE;

#pragma mark - Private

svg_status_t isvgRenderNew(isvg_render_t **render) {
    *render = malloc( sizeof( isvg_render_t ));
    if ( *render == NULL ) return SVG_STATUS_NO_MEMORY;
    ( *render )->viewportWidth = 450;
    ( *render )->viewportHeight = 450;
	isvg_render_state_t *state;
	isvgRenderStateCreate( &state );
	state->viewportWidth = (*render)->viewportWidth;
	state->viewportHeight = (*render)->viewportHeight;
    (*render)->state = state;
    return SVG_STATUS_SUCCESS;
}

svg_status_t isvgRenderDestroy( isvg_render_t *render ) {
    isvgRenderPopState( render );
    free ( render );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgRenderPushState( isvg_render_t *render ) {
    myLog( "Render push state" );
    if ( render->state == NULL ) {
		render->state = isvgRenderStatePush( render->state );
		render->state->viewportWidth = render->viewportWidth;
		render->state->viewportHeight = render->viewportHeight;
    } else {
		render->state = isvgRenderStatePush( render->state );
    }
    if ( render->state == NULL )
		return SVG_STATUS_NO_MEMORY;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgRenderPopState( isvg_render_t *render ) {
    myLog( "Render pop state" );
    render->state = isvgRenderStatePop( render->state );
    return SVG_STATUS_SUCCESS;
}

svg_status_t isvgRenderLengthToPixel( isvg_render_t *render, svg_length_t *length, double *pixel ) {
    double width, height;
	if ( dpi == 0 ) {
        CGSize screenSize = [ UIScreen mainScreen ].bounds.size;
        if ( screenSize.width == 320 ) {
            dpi = DPI_IPHONE_3;
        } else if ( screenSize.width == 640 ) {
            dpi = DPI_IPHONE_4;
        } else if ( screenSize.width == 1024 ) {
            dpi = DPI_IPAD;
        } else {
            dpi = DPI_IPAD_NEW;
        }
    }
    switch ( length->unit ) {
		case SVG_LENGTH_UNIT_PX:
			*pixel = length->value;
			break;
		case SVG_LENGTH_UNIT_CM:
			*pixel = (length->value / 2.54) * dpi;
			break;
		case SVG_LENGTH_UNIT_MM:
			*pixel = (length->value / 25.4) * dpi;
			break;
		case SVG_LENGTH_UNIT_IN:
			*pixel = length->value * dpi;
			break;
		case SVG_LENGTH_UNIT_PT:
			*pixel = (length->value / 72.0) * dpi;
			break;
		case SVG_LENGTH_UNIT_PC:
			*pixel = (length->value / 6.0) * dpi;
			break;
		case SVG_LENGTH_UNIT_EM:
			*pixel = length->value * render->state->fontSize;
			break;
		case SVG_LENGTH_UNIT_EX:
			*pixel = length->value * render->state->fontSize / 2.0;
			break;
		case SVG_LENGTH_UNIT_PCT:
			if ( render == NULL ) return length->value;
			if ( render->state->bbox ) {
				width = 1.0;
				height = 1.0;
			} else {
				width = render->state->viewportWidth;
				height = render->state->viewportHeight;
			}
			if ( length->orientation == SVG_LENGTH_ORIENTATION_HORIZONTAL )
				*pixel = ( length->value / 100.0 ) * width;
			else if ( length->orientation == SVG_LENGTH_ORIENTATION_VERTICAL )
				*pixel = ( length->value / 100.0 ) * height;
			else
				*pixel = ( length->value / 100.0 ) * sqrt( pow( width, 2 ) + pow( height, 2 )) * sqrt( 2 );
			break;
		default:
			*pixel = length->value;
    }
	
    return SVG_STATUS_SUCCESS;
}

#pragma mark Hierarchy

static svg_status_t isvgBeginGroup( void *closure, double opacity ) {
    myLog( "Begin group with opacity %f", opacity );
	isvg_render_t *render = closure;
	isvgRenderPushState( render );
    render->state->opacity = opacity;
    CGContextSaveGState( render->state->context );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgBeginElement( void *closure ) {
    myLog( "Begin element" );
	isvg_render_t *render = closure;
    isvgRenderPushState( render );
    CGContextSaveGState( render->state->context );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgEndElement( void *closure ) {
    myLog( "End element" );
	isvg_render_t *render = closure;
	isvgRenderPopState( render );
    CGContextRestoreGState( render->state->context );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgEndGroup( void *closure, double opacity ) {
    myLog( "End group with opacity %f", opacity );
	isvg_render_t *render = closure;
	isvgRenderPopState( render );
    CGContextRestoreGState( render->state->context );
    return SVG_STATUS_SUCCESS;
}

#pragma mark Path creation

static svg_status_t isvgMoveTo( void *closure, double x, double y ) {
	isvg_render_t *render = closure;
    myLog( "\tMove to point %f, %f", x, y );
	CGPathMoveToPoint( render->state->path, NULL, x, y );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgLineTo( void *closure, double x, double y ) {
	isvg_render_t *render = closure;
    myLog("\tLine to %f, %f",x, y);
    CGPathAddLineToPoint( render->state->path, NULL, x, y );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgCurveTo( void *closure,
						 double x1, double y1,
						 double x2, double y2,
						 double x3, double y3 ) {
	isvg_render_t *render = closure;
    myLog("\tCurve to %f, %f, %f, %f, %f, %f", x1, y1, x2, y2, x3, y3);
    CGPathAddCurveToPoint( render->state->path, NULL, x1, y1, x2, y2, x3, y3 );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgQuadraticCurveTo( void *closure,
								  double x1, double y1,
								  double x2, double y2 ) {
	isvg_render_t *render = closure;
    myLog("\tQuadratic curve to %fx%f %fx%f", x1, y1, x2, y2);
    CGPathAddQuadCurveToPoint( render->state->path, NULL, x1, y1, x2, y2 );
    return SVG_STATUS_SUCCESS;
}

void isvgAddArcSegment( void *closure,
                       double xc, double yc,
                       double th0, double th1, double rx, double ry,
                       double x_axis_rotation ) {
    double x1, y1, x2, y2, x3, y3;
    double t;
    double th_half;
    double f, sinf, cosf;
    
    f = x_axis_rotation * M_PI / 180.0;
    sinf = sin( f );
    cosf = cos( f );
    
    th_half = 0.5 * ( th1 - th0 );
    t = ( 8.0 / 3.0 ) * sin( th_half * 0.5 ) * sin( th_half * 0.5 ) / sin( th_half );
    x1 = rx * ( cos( th0 ) - t * sin( th0 ));
    y1 = ry * ( sin( th0 ) + t * cos( th0 ));
    x3 = rx * cos( th1 );
    y3 = ry * sin( th1 );
    x2 = x3 + rx * ( t * sin( th1 ));
    y2 = y3 + ry * ( -t * cos( th1 ));
    
    isvgCurveTo( closure,
                xc + cosf * x1 - sinf * y1,
                yc + sinf * x1 + cosf * y1,
                xc + cosf * x2 - sinf * y2,
                yc + sinf * x2 + cosf * y2,
                xc + cosf * x3 - sinf * y3,
                yc + sinf * x3 + cosf * y3 );
}

// Based on rsvg_path_arc of librsvg
static svg_status_t isvgArcTo(void *closure,
					   double	rx,
					   double	ry,
					   double	x_axis_rotation,
					   int	large_arc_flag,
					   int	sweep_flag,
					   double	x,
					   double	y) {
	isvg_render_t *render = closure;
    myLog("\tArc to %fx%f %fx%f", rx, ry, x, y);
    double f, sinf, cosf;
    double x1, y1, x2, y2;
    double x1_, y1_;
    double cx_, cy_, cx, cy;
    double gamma;
    double theta1, delta_theta;
    double k1, k2, k3, k4, k5;
    
    int i, n_segs;
    
    CGPoint point = CGPathGetCurrentPoint( render->state->path );
    x1 = point.x;
    y1 = point.y;
    
    x2 = x;
    y2 = y;
    
    if ( x1 == x2 && y1 == y2 )
        return SVG_STATUS_SUCCESS;
    
    f = x_axis_rotation * M_PI / 180.0;
    sinf = sin(f);
    cosf = cos(f);
    
    if (( fabs(rx) < DBL_EPSILON ) || ( fabs(ry) < DBL_EPSILON )) {
        isvgLineTo( closure, x, y );
        return SVG_STATUS_SUCCESS;
    }
    
    if ( rx < 0 ) rx = -rx;
    if ( ry < 0 ) ry = -ry;
    
    k1 = ( x1 - x2 ) / 2;
    k2 = ( y1 - y2 ) / 2;
    
    x1_ = cosf * k1 + sinf * k2;
    y1_ = -sinf * k1 + cosf * k2;
    
    gamma = ( x1_ * x1_ ) / ( rx * rx ) + ( y1_ * y1_ ) / ( ry * ry );
    if ( gamma > 1 ) {
        rx *= sqrt( gamma );
        ry *= sqrt( gamma );
    }
        
    k1 = rx * rx * y1_ * y1_ + ry * ry * x1_ * x1_;
    if( k1 == 0 )
        return SVG_STATUS_SUCCESS;
    
    k1 = sqrt( fabs(( rx * rx * ry * ry ) / k1 - 1 ));
    if( sweep_flag == large_arc_flag )
        k1 = -k1;
    
    cx_ = k1 * rx * y1_ / ry;
    cy_ = -k1 * ry * x1_ / rx;
    
    cx = cosf * cx_ - sinf * cy_ + ( x1 + x2 ) / 2;
    cy = sinf * cx_ + cosf * cy_ + ( y1 + y2 ) / 2;
        
    k1 = ( x1_ - cx_ ) / rx;
    k2 = ( y1_ - cy_ ) / ry;
    k3 = ( -x1_ - cx_ ) / rx;
    k4 = ( -y1_ - cy_ ) / ry;
    
    k5 = sqrt( fabs( k1 * k1 + k2 * k2 ));
    if ( k5 == 0 ) return SVG_STATUS_SUCCESS;
    
    k5 = k1 / k5;
    if( k5 < -1 ) k5 = -1;
    else if ( k5 > 1 ) k5 = 1;
    theta1 = acos( k5 );
    if ( k2 < 0 ) theta1 = -theta1;
        
    k5 = sqrt( fabs(( k1 * k1 + k2 * k2 ) * ( k3 * k3 + k4 * k4 )));
    if ( k5 == 0 ) return SVG_STATUS_SUCCESS;
    
    k5 = ( k1 * k3 + k2 * k4 ) / k5;
    if ( k5 < -1 ) k5 = -1;
    else if ( k5 > 1 ) k5 = 1;
    delta_theta = acos( k5 );
    if ( k1 * k4 - k3 * k2 < 0 ) delta_theta = -delta_theta;
    
    if ( sweep_flag && delta_theta < 0 )
        delta_theta += M_PI * 2;
    else if ( !sweep_flag && delta_theta > 0 )
        delta_theta -= M_PI * 2;
        
    n_segs = ceil( fabs( delta_theta / ( M_PI * 0.5 + 0.001 )));
    
    for (i = 0; i < n_segs; i++)
        isvgAddArcSegment( closure, cx, cy,
                          theta1 + i * delta_theta / n_segs,
                          theta1 + (i + 1) * delta_theta / n_segs,
                          rx, ry, x_axis_rotation );
    
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgClosePath( void *closure ) {
	isvg_render_t *render = closure;
    myLog("\tClose path");
    CGPathCloseSubpath( render->state->path );
    return SVG_STATUS_SUCCESS;
}

#pragma mark Style

static svg_status_t isvgSetColor( void *closure, const svg_color_t *color ) {
	isvg_render_t *render = closure;
    myLog("\tSet color %x", color->rgb);
    render->state->color = *color;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFillOpacity( void *closure, double fill_opacity ) {
	isvg_render_t *render = closure;
    myLog("\tSet fill opacity %f", fill_opacity);
    render->state->fillOpacity = fill_opacity;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFillPaint( void *closure, const svg_paint_t *paint ) {
	isvg_render_t *render = closure;
    char *s;
    render->state->fillPaint = *paint;
    switch ( paint->type ) {
        case SVG_PAINT_TYPE_NONE:
            s = "None";
            break;
        case SVG_PAINT_TYPE_COLOR:
            s = "Color";
            break;
        case SVG_PAINT_TYPE_PATTERN:
            s = "Pattern";
            break;
        case SVG_PAINT_TYPE_GRADIENT:
            s = "Gradient";
            break;
    }
    myLog("\tSet fill paint type=%s color=%x", s, paint->p.color.rgb );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFillRule( void *closure, svg_fill_rule_t fill_rule ) {
	isvg_render_t *render = closure;
    myLog("\tSet fill rule %d", fill_rule );
	render->state->fileRule = fill_rule;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFontFamily( void *closure, const char *family ) {
	isvg_render_t *render = closure;
    myLog("\tSet font famil %s", family);
	if ( render->state->fontFamily ) free( render->state->fontFamily );
	render->state->fontFamily = strdup( family );
	render->state->fontDirty = TRUE;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFontSize( void *closure, double size ) {
	isvg_render_t *render = closure;
    myLog("\tSet font size %f", size);
	render->state->fontSize = size;
	render->state->fontDirty = TRUE;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFontStyle( void *closure, svg_font_style_t font_style ) {
	isvg_render_t *render = closure;
    myLog("\tSet font style %d", font_style);
	render->state->fontStyle = font_style;
	render->state->fontDirty = TRUE;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetFontWeight( void *closure, unsigned int font_weight ) {
	isvg_render_t *render = closure;
    myLog("\tSet font weight %d", font_weight);
	render->state->fontWeight = font_weight;
	render->state->fontDirty = TRUE;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetOpacity( void *closure, double opacity ) {
	isvg_render_t *render = closure;
    myLog("\tSet opacity %f", opacity);
	render->state->opacity = opacity;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeDashArray( void *closure, double *dash_array, int num_dashes ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke dash array %d", num_dashes);
    free( render->state->dash );
    render->state->dash = NULL;
    render->state->numDashes = num_dashes;
    
    if ( render->state->numDashes ) {
        render->state->dash = malloc( render->state->numDashes * sizeof( double ));
        if ( render->state->dash == NULL )
            return SVG_STATUS_NO_MEMORY;
        
        memcpy( render->state->dash, dash_array, render->state->numDashes * sizeof( double ));
        
        CGContextSetLineDash( render->state->context, render->state->dashOffset, ( float* )render->state->dash, render->state->numDashes );
    }
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeDashOffset( void *closure, svg_length_t *offset ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke dash offset %f", offset->value);
    double dashOff;
    isvgRenderLengthToPixel( render, offset, &dashOff );
    render->state->dashOffset = dashOff;
    if ( render->state->numDashes )
        CGContextSetLineDash( render->state->context, render->state->dashOffset, ( float* )render->state->dash, render->state->numDashes );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeLineCap( void *closure, svg_stroke_line_cap_t line_cap ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke line cap");
    switch ( line_cap ) {
        case SVG_STROKE_LINE_CAP_BUTT:
            render->state->lineCap = kCGLineCapButt;
            break;
        case SVG_STROKE_LINE_CAP_ROUND:
            render->state->lineCap = kCGLineCapRound;
            break;
        case SVG_STROKE_LINE_CAP_SQUARE:
            render->state->lineCap = kCGLineCapSquare;
            break;
    }
    CGContextSetLineCap( render->state->context, render->state->lineCap );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeLineJoin( void *closure, svg_stroke_line_join_t line_join ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke line join");
    switch ( line_join ) {
        case SVG_STROKE_LINE_JOIN_BEVEL:
            render->state->lineJoin = kCGLineJoinBevel;
            break;
        case SVG_STROKE_LINE_JOIN_MITER:
            render->state->lineJoin = kCGLineJoinMiter;
            break;
        case SVG_STROKE_LINE_JOIN_ROUND:
            render->state->lineJoin = kCGLineJoinRound;
            break;
    }
    CGContextSetLineJoin( render->state->context, render->state->lineJoin );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeMiterLimit( void *closure, double limit ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke miter limit %f", limit);
    CGContextSetMiterLimit( render->state->context, limit );
    render->state->miterLimit = limit;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeOpacity( void *closure, double stroke_opacity ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke opacity %f", stroke_opacity);
    render->state->strokeOpacity = stroke_opacity;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokePaint( void *closure, const svg_paint_t *paint ) {
	isvg_render_t *render = closure;
    render->state->strokePaint = *paint;
    char *s;
    switch ( paint->type ) {
        case SVG_PAINT_TYPE_NONE:
            s = "None";
            break;
        case SVG_PAINT_TYPE_COLOR:
            s = "Color";
            break;
        case SVG_PAINT_TYPE_PATTERN:
            s = "Pattern";
            break;
        case SVG_PAINT_TYPE_GRADIENT:
            s = "Gradient";
            break;
    }
    myLog("\tSet stroke paint type=%s color=%x", s, paint->p.color.rgb );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetStrokeWidth( void *closure, svg_length_t *width ) {
	isvg_render_t *render = closure;
    myLog("\tSet stroke width %f", width->value);
	double w;
    isvgRenderLengthToPixel( render, width, &w );
    CGContextSetLineWidth( render->state->context, w );
    render->state->lineWidth = w;
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetTextAnchor( void *closure, svg_text_anchor_t text_anchor ) {
	isvg_render_t *render = closure;
    myLog("\tSet text anchor %d", text_anchor);
	render->state->textAnchor = text_anchor;
    return SVG_STATUS_SUCCESS;
}

#pragma mark Transform

static svg_status_t isvgTransform(void *closure,
						   double a, double b,
						   double c, double d,
						   double e, double f) {
	isvg_render_t *render = closure;
    CGContextConcatCTM( render->state->context, CGAffineTransformMake( a, b, c, d, e, f ));
    myLog("Transform %f %f %f %f %f %f", a, b, c, d, e, f);
    return SVG_STATUS_SUCCESS;
}

// Not sure about this function
static svg_status_t isvgApplyViewBox(void *closure,
							  svg_view_box_t view_box,
							  svg_length_t *width,
							  svg_length_t *height) {
	isvg_render_t *render = closure;
    double vpar, svgar;
    double logic_width, logic_height;
    double logic_x, logic_y;
    double phys_width, phys_height;
    isvgRenderLengthToPixel( render, width, &phys_width);
    isvgRenderLengthToPixel( render, height, &phys_height );
    
	myLog("Apply view box %fx%f %fx%f", view_box.box.width, view_box.box.height, phys_width, phys_height );
//	return SVG_STATUS_SUCCESS;
	
    vpar = view_box.box.width / view_box.box.height;
    svgar = phys_width / phys_height;
    logic_x = view_box.box.x;
    logic_y = view_box.box.y;
    logic_width = view_box.box.width;
    logic_height = view_box.box.height;
    
    if ( view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_NONE ) {
        CGContextScaleCTM( render->state->context, phys_width / logic_width, phys_height / logic_height );
        CGContextTranslateCTM( render->state->context, -logic_x, -logic_y );
    } else if (( vpar < svgar && view_box.meet_or_slice == SVG_MEET_OR_SLICE_MEET ) ||
    	     ( vpar >= svgar && view_box.meet_or_slice == SVG_MEET_OR_SLICE_SLICE )) {
        CGContextScaleCTM( render->state->context, phys_height / logic_height, phys_height / logic_height);

        if ( view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMINYMIN ||
            view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMINYMID ||
            view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMINYMAX )
            CGContextTranslateCTM( render->state->context, -logic_x, -logic_y );
        else if(view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMIDYMIN ||
                view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMIDYMID ||
                view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMIDYMAX)
            CGContextTranslateCTM( render->state->context,
                             -logic_x - (logic_width - phys_width * logic_height / phys_height) / 2,
                             -logic_y );
        else
            CGContextTranslateCTM( render->state->context,
                             -logic_x - (logic_width - phys_width * logic_height / phys_height),
                             -logic_y);
    } else {
        CGContextScaleCTM( render->state->context, phys_width / logic_width, phys_width / logic_width );
        
        if ( view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMINYMIN ||
            view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMIDYMIN ||
            view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMAXYMIN )
            CGContextTranslateCTM( render->state->context, -logic_x, -logic_y );
        else if(view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMINYMID ||
                view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMIDYMID ||
                view_box.aspect_ratio == SVG_PRESERVE_ASPECT_RATIO_XMAXYMID )
            CGContextTranslateCTM( render->state->context,
                             -logic_x,
                             -logic_y - (logic_height - phys_height * logic_width / phys_width) / 2);
        else
            CGContextTranslateCTM( render->state->context,
                             -logic_x,
                             -logic_y - (logic_height - phys_height * logic_width / phys_width));
    }
    myLog( "\tCurrent transform %s", [ NSStringFromCGAffineTransform( CGContextGetCTM( render->state->context )) UTF8String ]);
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgSetViewportDimension(void *closure,
									  svg_length_t *width,
									  svg_length_t *height) {
	isvg_render_t *render = closure;
	double w, h;
	isvgRenderLengthToPixel( render, width, &w );
	isvgRenderLengthToPixel( render, height, &h );
//    CGContextClipToRect( render->state->context, CGRectMake( 0, 0, w, h ));
    render->state->viewportWidth = w;
    render->state->viewportHeight = h;
    myLog("Set viewport dimension %fx%f", w, h );
    return SVG_STATUS_SUCCESS;
}

#pragma mark Drawing

static svg_status_t isvgRenderLine(void *closure,
							svg_length_t *x1,
							svg_length_t *y1,
							svg_length_t *x2,
							svg_length_t *y2) {
	isvg_render_t *render = closure;
    myLog("Render line %fx%f %fx%f", x1->value, y1->value, x2->value, y2->value);
	double x_1, x_2, y_1, y_2;
    svg_status_t status;
	isvgRenderLengthToPixel( render, x1, &x_1 );
	isvgRenderLengthToPixel( render, x2, &x_2 );
	isvgRenderLengthToPixel( render, y1, &y_1 );
	isvgRenderLengthToPixel( render, y2, &y_2 );
    isvgMoveTo( closure, x_1, y_1 );
    isvgLineTo( closure, x_2, y_2 );
	CGPathCloseSubpath( render->state->path );
    status = isvgRenderPath( closure );
    return status;
}

static void _isvgMaskForStrokeGradient( isvg_render_t *render ) {
    UIGraphicsBeginImageContext( CGSizeMake( render->viewportWidth, render->viewportHeight ));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transform = CGContextGetCTM( render->state->context );
    CGContextConcatCTM( context, transform );
    CGContextSetStrokeColorWithColor( context, [[ UIColor blackColor ] CGColor ]);
    CGContextSetStrokeColorSpace( context, CGColorSpaceCreateDeviceRGB());
    if ( render->state->numDashes > 0 )
        CGContextSetLineDash( context, render->state->dashOffset, ( float* )render->state->dash, render->state->numDashes );
    CGContextSetLineCap( context, render->state->lineCap );
    CGContextSetLineJoin( context, render->state->lineJoin );
    CGContextSetLineWidth( context, render->state->lineWidth );
    CGContextSetMiterLimit( context, render->state->miterLimit );
    CGContextAddPath( context, render->state->path );
    CGContextStrokePath( context );
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    transform = CGContextGetCTM( render->state->context );
    transform = CGAffineTransformInvert( transform );
    CGContextConcatCTM( render->state->context, transform );
    CGContextTranslateCTM( render->state->context, 0, render->viewportHeight );
    CGContextScaleCTM( render->state->context, 1.0, -1.0 );
    CGRect clipRect = CGRectMake( 0, 0, render->viewportWidth, render->viewportHeight ); //CGRectApplyAffineTransform( CGRectMake( 0, 0, render->viewportWidth, render->viewportHeight ), transform );
    CGContextClipToMask( render->state->context, clipRect, image.CGImage );
}

static bool _isvgIntersection2PointsWithRect( CGRect bounds, CGPoint point1, CGPoint point2, CGPoint *intersect1, CGPoint *intersect2 ) {
	if ( point1.x == point2.x && point1.y == point2.y ) {
		return FALSE;
	} else if ( point1.x == point2.x ) {
		intersect1->x = intersect2->x = point1.x;
		intersect1->y = bounds.origin.y;
		intersect2->y = bounds.origin.y + bounds.size.height;
	} else if ( point1.y == point2.y ) {
		intersect1->x = bounds.origin.x;
		intersect2->x = bounds.origin.x + bounds.size.width;
		intersect1->y = intersect2->y = point1.y;
	} else {
		double m = ( point2.y - point1.y ) / ( point2.x - point1.x );
		bool p1Set = FALSE;
		CGPoint ins = CGPointZero;
		ins.x = bounds.origin.x;
		ins.y = m * ( ins.x - point1.x ) + point1.y;
		if ( CGRectContainsPoint( bounds, ins )) {
			*intersect1 = ins;
			p1Set = TRUE;
		}
		ins.x = bounds.origin.x + bounds.size.width;
		ins.y = m * ( ins.x - point1.x ) + point1.y;
		if ( CGRectContainsPoint( bounds, ins )) {
			if ( p1Set ) {
				*intersect2 = ins;
				return TRUE;
			}
			*intersect1 = ins;
			p1Set = TRUE;
		}
		ins.y = bounds.origin.y;
		ins.x = ( ins.y - point1.y ) / m + point1.x;
		if ( CGRectContainsPoint( bounds, ins )) {
			if ( p1Set ) {
				*intersect2 = ins;
				return TRUE;
			}
			*intersect1 = ins;
			p1Set = TRUE;
		}
		ins.y = bounds.origin.y + bounds.size.height;
		ins.x = ( ins.y - point1.y ) / m + point1.x;
		if ( CGRectContainsPoint( bounds, ins )) {
			if ( p1Set ) {
				*intersect2 = ins;
				return TRUE;
			}
			*intersect1 = ins;
			p1Set = TRUE;
		}
	}
	return TRUE;
}

static double _isvg2PointsDistance( CGPoint point1, CGPoint point2 ) {
	return sqrt( pow( point2.x - point1.x, 2 ) + pow( point2.y - point1.y, 2 ));
}

static bool _isvgExpandedPoint( CGPoint point1, CGPoint point2, CGPoint *exPoint, double distance ) {
    CGPoint p1 = CGPointZero;
    CGPoint p2 = CGPointZero;
    if ( point1.x == point2.x && point1.y == point2.y ) {
		return FALSE;
	} else if ( point1.x == point2.x ) {
		p1.x = p2.x = point1.x;
        p1.y = point1.y - distance;
        p2.y = point2.y + distance;
	} else if ( point1.y == point2.y ) {
		p1.y = p2.y = point1.y;
        p1.x = point1.x - distance;
        p2.x = point1.x + distance;
	} else {
        double m = ( point2.y - point1.y ) / ( point2.x - point1.x );
        double n = sqrt( pow( distance, 2.0 ) / ( pow( m, 2.0 ) + 1 ));
        p1.x = point1.x - n;
        p2.x = point1.x + n;
        p1.y = m * ( p1.x - point1.x ) + point1.y;
        p2.y = m * ( p2.x - point1.x ) + point1.y;
    }
    double d1 = _isvg2PointsDistance( p1, point2 );
    double d2 = _isvg2PointsDistance( p2, point2 );
    if ( d1 < d2 ) {
        *exPoint = p2;
    } else {
        *exPoint = p1;
    }
    return TRUE;
}

static void _isvgCreateGradientBrush( svg_gradient_t *svgGradient, int totalNumLocs, bool reverse, CGGradientRef *gradient ) {
    size_t numLocs = svgGradient->num_stops;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat *locations = malloc( sizeof( CGFloat ) * totalNumLocs );
    CGFloat *components = malloc( sizeof( CGFloat ) * totalNumLocs * 4 );
    int locId = 0;
    if ( svgGradient->spread == SVG_GRADIENT_SPREAD_REFLECT ) {
        if ( reverse ) {
            svg_gradient_stop_t *stop = &svgGradient->stops[numLocs - 1];
            locations[locId] = 1.0 - ( CGFloat )stop->offset;
            int j = locId * 4;
            components[j] = svg_color_get_red( &stop->color ) / 255.0;
            components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
            components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
            components[j + 3] = stop->opacity;
        } else {
            svg_gradient_stop_t *stop = &svgGradient->stops[0];
            locations[locId] = ( CGFloat )stop->offset;
            int j = locId * 4;
            components[j] = svg_color_get_red( &stop->color ) / 255.0;
            components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
            components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
            components[j + 3] = stop->opacity;
        }
        locId++;
        while ( locId < totalNumLocs ) {
            if ( reverse ) {
                for ( int i = numLocs - 2; i >= 0; i-- ) {
                    svg_gradient_stop_t *stop = &svgGradient->stops[i];
                    locations[locId] = 1.0 - ( CGFloat )stop->offset;
                    int j = locId * 4;
                    components[j] = svg_color_get_red( &stop->color ) / 255.0;
                    components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
                    components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
                    components[j + 3] = stop->opacity;
                    locId++;
                }
            } else {
                for ( int i = 1; i < numLocs; i++ ) {
                    svg_gradient_stop_t *stop = &svgGradient->stops[i];
                    locations[locId] = ( CGFloat )stop->offset;
                    int j = locId * 4;
                    components[j] = svg_color_get_red( &stop->color ) / 255.0;
                    components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
                    components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
                    components[j + 3] = stop->opacity;
                    locId++;
                }
            }
            reverse = !reverse;
        }
    } else { // repeat
        while ( locId < totalNumLocs ) {
            for ( int i = 1; i < numLocs; i++ ) {
                svg_gradient_stop_t *stop = &svgGradient->stops[i];
                locations[locId] = ( CGFloat )stop->offset;
                int j = locId * 4;
                components[j] = svg_color_get_red( &stop->color ) / 255.0;
                components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
                components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
                components[j + 3] = stop->opacity;
                locId++;
            }
        }
    }
    
    *gradient = CGGradientCreateWithColorComponents( colorSpace, components, locations, totalNumLocs );
    CGColorSpaceRelease( colorSpace );
}

static void _isvgRenderGradient( isvg_render_t *render, bool isStroking ) {
	CGContextSaveGState( render->state->context );
        
    if ( !isStroking ) {
        CGContextAddPath( render->state->context, render->state->path );
        CGContextClip( render->state->context );
    } 
//	else {
//        CGContextAddPath( render->state->context, render->state->path );
//        CGContextStrokePath( render->state->context );
//    }
    
	svg_gradient_t *gradient = isStroking ? render->state->strokePaint.p.gradient : render->state->fillPaint.p.gradient;
    
	CGAffineTransform gradientTransform = CGAffineTransformMake( gradient->transform[0], gradient->transform[1],
                                                              gradient->transform[2], gradient->transform[3],
                                                              gradient->transform[4], gradient->transform[5] );
    myLog( "\tGradient transform %f, %f, %f, %f, %f, %f", gradient->transform[0], gradient->transform[1],
           gradient->transform[2], gradient->transform[3],
           gradient->transform[4], gradient->transform[5] );
    
	switch ( gradient->units ) {
		case SVG_GRADIENT_UNITS_USER:
			myLog( "\tGradient units user" );
			break;
		case SVG_GRADIENT_UNITS_BBOX:
		{
			CGRect aRect = CGPathGetBoundingBox( render->state->path );
			CGContextTranslateCTM( render->state->context, aRect.origin.x, aRect.origin.y );
			CGContextScaleCTM( render->state->context, aRect.size.width, aRect.size.height );
			myLog( "\tGradient units bbox %f %f, %f %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height );
			render->state->bbox = 1;
		} break;
	}
	
	switch ( gradient->spread ) {
		case SVG_GRADIENT_SPREAD_REFLECT:
			myLog( "\tGradient reflect" );
		case SVG_GRADIENT_SPREAD_REPEAT:
        {
			myLog( "\tGradient repeat" );
            CGRect bounds = CGPathGetBoundingBox( render->state->path );
			switch (gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					double x1, y1, x2, y2;
					
					isvgRenderLengthToPixel( render, &gradient->u.linear.x1, &x1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y1, &y1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.x2, &x2 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y2, &y2 );
					myLog( "\tGradient linear %f %f; %f %f", x1, y1, x2, y2 );
					
					// Expand gradient start & end point to context border
					CGPoint p1 = CGPointMake( x1, y1 );
					CGPoint p2 = CGPointMake( x2, y2 );
					double p1p2 = _isvg2PointsDistance( p1, p1 );
					CGPoint p3, p4;
					_isvgIntersection2PointsWithRect( bounds, p1, p2, &p3, &p4 );
					double d1 = _isvg2PointsDistance( p1, p3 ); // distance between 1st point & 1st expanded point
					double d2 = _isvg2PointsDistance( p2, p3 ); // distance betwwen 2 2nd points
					if ( d1 < d2 ) {
						d2 = _isvg2PointsDistance( p2, p4 );
					} else {
						d1 = _isvg2PointsDistance( p1, p4 );
					}
					// Expand stop points
					CGPoint p12, p22; // 2 expanded points
					
                    int extLocs1 = d1 / p1p2;
					if ( fmod( d1, p1p2 ) > 0 ) extLocs1++;
					d1 = extLocs1 * p1p2;
					if ( d1 > 0 ) _isvgExpandedPoint( p1, p2, &p12, d1 );
                    
					int extLocs2 = d2 / p1p2;
					if ( fmod( d2, p1p2 ) > 0 ) extLocs2++;
                    d2 = extLocs2 * p1p2;
                    if ( d2 > 0 ) _isvgExpandedPoint( p2, p1, &p22, d2 );
                    
					CGGradientRef iGradient;
                    _isvgCreateGradientBrush( gradient, gradient->num_stops + extLocs1 + extLocs2, (( extLocs1 % 2 ) == 1 ), &iGradient );
					
					if ( isStroking ) _isvgMaskForStrokeGradient( render );
					
					CGContextDrawLinearGradient( render->state->context, iGradient,
												CGPointApplyAffineTransform( p12, gradientTransform ),
                                                CGPointApplyAffineTransform( p22, gradientTransform ),
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
					myLog( "\tGradient num of stop %d", gradient->num_stops );
					CGGradientRelease( iGradient );
				}
					break;
				case SVG_GRADIENT_RADIAL:
				{
					double cx, cy, r, fx, fy;
					
					isvgRenderLengthToPixel( render, &gradient->u.radial.cx, &cx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.cy, &cy );
					isvgRenderLengthToPixel( render, &gradient->u.radial.r, &r );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fx, &fx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fy, &fy );
					myLog( "\tGradient radical c=%fx%f r=%f f=%fx%f", cx, cy, r, fx, fy );
					
                    CGPoint cornerTL = bounds.origin;
                    CGPoint cornerTR = CGPointMake( bounds.origin.x + bounds.size.width, bounds.origin.y );
                    CGPoint cornerBL = CGPointMake( bounds.origin.x, bounds.origin.y + bounds.size.height );
                    CGPoint cornerBR = CGPointMake( bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height );
                    CGPoint centerP = CGPointMake( cx, cy );
                    double dCTL = _isvg2PointsDistance( centerP, cornerTL );
                    double dCTR = _isvg2PointsDistance( centerP, cornerTR );
                    double dCBL = _isvg2PointsDistance( centerP, cornerBL );
                    double dCBR = _isvg2PointsDistance( centerP, cornerBR );
                    double d = fmax( fmax( dCTL, dCTR ), fmax( dCBL, dCBR ));
                    
                    int extLocs = d / r;
                    if ( fmod( d, r ) > 0 ) extLocs++;
                    d = extLocs * r;
                    
					CGGradientRef iGradient;
                    _isvgCreateGradientBrush( gradient, gradient->num_stops + extLocs, FALSE, &iGradient );
					
					if ( isStroking ) _isvgMaskForStrokeGradient( render );
					
					CGContextDrawRadialGradient( render->state->context, iGradient,
                                                CGPointApplyAffineTransform( CGPointMake( fx, fy ), gradientTransform ), 0.0,
                                                CGPointApplyAffineTransform( CGPointMake( cx, cy ), gradientTransform ), d,
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
					myLog( "\tGradient num of stop %d", gradient->num_stops );
					CGGradientRelease( iGradient );
				}	
				break;
			}
			break;
        }
		default:
			myLog( "\tGradient default" );
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			size_t numLocs = gradient->num_stops;
			CGFloat *locations = malloc( sizeof( CGFloat ) * numLocs );
			CGFloat *components = malloc( sizeof( CGFloat ) * numLocs * 4 );
			for ( int i = 0; i < numLocs; i++ ) {
				svg_gradient_stop_t *stop = &gradient->stops[i];
				locations[i] = ( CGFloat )stop->offset;
				int j = i * 4;
				components[j] = svg_color_get_red( &stop->color ) / 255.0;
				components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
				components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
				components[j + 3] = stop->opacity;
                myLog( "\t\tGradient stop %d at %f color=%x:%f", i, stop->offset, stop->color.rgb, stop->opacity );
			}
			CGGradientRef iGradient = CGGradientCreateWithColorComponents( colorSpace, components, locations, numLocs );
            
			if ( isStroking ) _isvgMaskForStrokeGradient( render );
                        
			switch (gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					double x1, y1, x2, y2;
					
					isvgRenderLengthToPixel( render, &gradient->u.linear.x1, &x1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y1, &y1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.x2, &x2 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y2, &y2 );
					myLog( "\tGradient linear %f %f; %f %f", x1, y1, x2, y2 );
					CGContextDrawLinearGradient( render->state->context, iGradient,
												CGPointApplyAffineTransform( CGPointMake( x1, y1 ), gradientTransform ),
                                                CGPointApplyAffineTransform( CGPointMake( x2, y2 ), gradientTransform ),
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
					
				}
					break;
				case SVG_GRADIENT_RADIAL:
				{
					double cx, cy, r, fx, fy;
					
					isvgRenderLengthToPixel( render, &gradient->u.radial.cx, &cx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.cy, &cy );
					isvgRenderLengthToPixel( render, &gradient->u.radial.r, &r );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fx, &fx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fy, &fy );
					myLog( "\tGradient radical c=%fx%f r=%f f=%fx%f", cx, cy, r, fx, fy );
					CGContextDrawRadialGradient( render->state->context, iGradient,
												CGPointApplyAffineTransform( CGPointMake( fx, fy ), gradientTransform ), 0.0,
                                                CGPointApplyAffineTransform( CGPointMake( cx, cy ), gradientTransform ), r,
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
				} break;
			}
			myLog( "\tGradient num of stop %d", gradient->num_stops );
			CGGradientRelease( iGradient );
			CGColorSpaceRelease( colorSpace );
			break;
	}

	render->state->bbox = 0;
	
	CGContextRestoreGState( render->state->context );
}

/*
void _isvgRenderPatternCell( void *info, CGContextRef context ) {
    myLog( "BEGIN RENDER PATTERN" );
    isvg_render_t *render = info;
    svg_element_t *patternElement = render->isStroke ? render->state->strokePaint.p.pattern_element : render->state->fillPaint.p.pattern_element;
    svg_pattern_t *svgPattern = svg_element_pattern( patternElement );
    isvgRenderPushState( render );
    CGContextRef parentContext = render->state->context;
    myLog( "Parent context %p current %p", parentContext, context );
    render->state->context = context;
	CGContextSetLineWidth( context, 1 );
    myLog( "Current transform: %s", [ NSStringFromCGAffineTransform( CGContextGetCTM( parentContext )) UTF8String ]);
//    CGContextConcatCTM( context, CGAffineTransformInvert( CGContextGetCTM( parentContext )));
    CGContextScaleCTM( context, 2.0, 2.0 );
    render->state->fillPaint.type = SVG_PAINT_TYPE_NONE;
    render->state->strokePaint.type = SVG_PAINT_TYPE_NONE;
    svg_element_render( svgPattern->group_element, &ISVG_RENDER_ENGINE, render );
    isvgRenderPopState( render );
    myLog( "END RENDER PATTERN" );
}

static void _isvgRenderPattern( isvg_render_t* render ) {
    svg_element_t *patternElement = render->isStroke ? render->state->strokePaint.p.pattern_element : render->state->fillPaint.p.pattern_element;
    svg_pattern_t *svgPattern = svg_element_pattern( patternElement );
    double px, py, pw, ph;
    isvgRenderLengthToPixel( render, &svgPattern->x, &px );
    isvgRenderLengthToPixel( render, &svgPattern->y, &py );
    isvgRenderLengthToPixel( render, &svgPattern->width, &pw );
    isvgRenderLengthToPixel( render, &svgPattern->height, &ph );
    CGPatternCallbacks callback = { 0, _isvgRenderPatternCell, NULL };
    CGPatternRef pattern = CGPatternCreate( render, CGRectMake( px, py, pw, ph ), CGAffineTransformIdentity, pw, ph, kCGPatternTilingNoDistortion, YES, &callback );
    CGColorSpaceRef colorSpace = CGColorSpaceCreatePattern( NULL );
    CGFloat alpha = 1.0;
    CGColorRef patternColor = CGColorCreateWithPattern( colorSpace, pattern, &alpha );
    CGColorSpaceRelease( colorSpace );
    CGPatternRelease( pattern );
    CGContextAddPath( render->state->context, render->state->path );
    if ( render->isStroke ) {
        CGContextSetStrokeColorWithColor( render->state->context, patternColor );
        CGContextStrokePath( render->state->context );
    } else {
        CGContextSetFillColorWithColor( render->state->context, patternColor );
        CGContextFillPath( render->state->context );
    }
}*/

static svg_status_t isvgRenderPath(void *closure) {
	isvg_render_t *render = closure;
//    CGPathCloseSubpath( render->state->path );
    myLog("Render path %p", &render->state->context );
    char *s;
    switch ( render->state->fillPaint.type ) {
        case SVG_PAINT_TYPE_NONE:
            s = "None";
            break;
        case SVG_PAINT_TYPE_COLOR:
            s = "Color";
            CGContextSetRGBFillColor( render->state->context,
                                     svg_color_get_red( &render->state->fillPaint.p.color ) / 255.0,
                                     svg_color_get_green( &render->state->fillPaint.p.color ) / 255.0,
                                     svg_color_get_blue( &render->state->fillPaint.p.color ) / 255.0,
                                     render->state->opacity * render->state->fillOpacity );
            CGContextAddPath( render->state->context, render->state->path );
			switch ( render->state->fileRule ) {
				case SVG_FILL_RULE_EVEN_ODD:
					CGContextEOFillPath( render->state->context );
					break;
				case SVG_FILL_RULE_NONZERO:
				default:
					CGContextFillPath( render->state->context );
					break;
			}
            break;
        case SVG_PAINT_TYPE_PATTERN:
            s = "Pattern";
//            render->isStroke = NO;
//            _isvgRenderPattern( render ); // too bad, ignore
            break;
        case SVG_PAINT_TYPE_GRADIENT:
            s = "Gradient";
			_isvgRenderGradient( render, FALSE );
            break;
    }
    myLog("\tFill type=%s color=%x opacity=%fx%f", s, render->state->fillPaint.p.color.rgb, render->state->opacity, render->state->fillOpacity );
    switch ( render->state->strokePaint.type ) {
        case SVG_PAINT_TYPE_NONE:
            s = "None";
            break;
        case SVG_PAINT_TYPE_COLOR:
            s = "Color";
            CGContextSetRGBStrokeColor( render->state->context,
                                       svg_color_get_red( &render->state->strokePaint.p.color ) / 255.0,
                                       svg_color_get_green( &render->state->strokePaint.p.color ) / 255.0,
                                       svg_color_get_blue( &render->state->strokePaint.p.color ) / 255.0,
                                       render->state->opacity * render->state->strokeOpacity );
            CGContextAddPath( render->state->context, render->state->path );
            CGContextStrokePath( render->state->context );
            break;
        case SVG_PAINT_TYPE_PATTERN:
            s = "Pattern";
//            render->isStroke = YES;
//            _isvgRenderPattern( render ); // too bad ignore
            break;
        case SVG_PAINT_TYPE_GRADIENT:
            s = "Gradient";
            _isvgRenderGradient( render, TRUE );
            break;
    }
    myLog("\tStroke type=%s color=%x opacity=%fx%f lineW=%f", s, render->state->strokePaint.p.color.rgb, render->state->opacity, render->state->strokeOpacity, render->state->lineWidth );
    return SVG_STATUS_SUCCESS;
}

static svg_status_t isvgRenderEllipse(void *closure,
							   svg_length_t *cx,
							   svg_length_t *cy,
							   svg_length_t *rx,
							   svg_length_t *ry) {
	isvg_render_t *render = closure;
	double c_x, c_y, r_x, r_y;
	isvgRenderLengthToPixel( render, cx, &c_x );
	isvgRenderLengthToPixel( render, cy, &c_y );
	isvgRenderLengthToPixel( render, rx, &r_x );
	isvgRenderLengthToPixel( render, ry, &r_y );
    myLog("Render ellipse %fx%f %fx%f", c_x, c_y, r_x, r_y );
    CGPathAddEllipseInRect( render->state->path, NULL, CGRectMake( cx->value - rx->value, cy->value - ry->value, 2 * rx->value, 2 * ry->value ));
	CGPathCloseSubpath( render->state->path );
    return isvgRenderPath( closure );
}

static svg_status_t isvgRenderRect(void *closure,
							svg_length_t *x,
							svg_length_t *y,
							svg_length_t *width,
							svg_length_t *height,
							svg_length_t *rx,
							svg_length_t *ry) {
	isvg_render_t *render = closure;
	double x1, y1, w, h, r_x, r_y;
    svg_status_t status;
	isvgRenderLengthToPixel( render, x, &x1 );
	isvgRenderLengthToPixel( render, y, &y1 );
	isvgRenderLengthToPixel( render, rx, &r_x );
	isvgRenderLengthToPixel( render, ry, &r_y );
	isvgRenderLengthToPixel( render, width, &w );
	isvgRenderLengthToPixel( render, height, &h );
    myLog("Render rect %fx%f %fx%f %fx%f", x1, y1, w, h, r_x, r_y );
    if ( r_x > 0 || r_y > 0 ) {
        isvgMoveTo( closure, x1 + r_x, y1 );
        isvgLineTo( closure, x1 + w - r_x, y1 );
        isvgArcTo( closure, r_x, r_y, 0, 0, 1, x1 + w, y1 + r_y );
        isvgLineTo( closure, x1 + w, y1 + h - r_y );
        isvgArcTo( closure, r_x, r_y, 0, 0, 1, x1 + w  - r_x, y1 + h );
        isvgLineTo( closure, x1 + r_x, y1 + h );
        isvgArcTo( closure, r_x, r_y, 0, 0, 1, x1, y1 + h - r_y );
        isvgLineTo( closure, x1, y1 + r_y );
        isvgArcTo( closure, r_x, r_y, 0, 0, 1, x1 + r_x, y1 );
    } else {
        isvgMoveTo( closure, x1, y1 );
        isvgLineTo( closure, x1 + w, y1 );
        isvgLineTo( closure, x1 + w, y1 + h );
        isvgLineTo( closure, x1, y1 + h );
    }
    CGPathCloseSubpath( render->state->path );
    status = isvgRenderPath( closure );
    return status;
}

static UIFont* _isvgSelectFont( isvg_render_t *render ) {
    bool isBold, isItalic;
    isBold = ( render->state->fontWeight > 700 );
    switch ( render->state->fontStyle ) {
        case SVG_FONT_STYLE_NORMAL:
            isItalic = NO;
            break;
        case SVG_FONT_STYLE_OBLIQUE:
        case SVG_FONT_STYLE_ITALIC:
            isItalic = YES;
            break;
    }
    char *s = render->state->fontFamily;
    s[0] = toupper( s[0] );
    int i = 0;
    while (s[i]) {
        s[i] = tolower(s[i]);
        i++;
    }
    NSString *fontName = [ NSString stringWithUTF8String:s ];
    NSArray *fonts = [ UIFont fontNamesForFamilyName:fontName ];
    if ( fonts.count == 0 ) {
        printf( "ISVG Warning: Can not load font '%s'. Use system font instead.\n", s );
        fontName = [[ UIFont systemFontOfSize:14 ]  fontName ];
        fonts = [ UIFont fontNamesForFamilyName:fontName ];
    }
    if ( isBold && isItalic ) {
        for ( NSString *s in fonts ) {
            NSString *s1 = [ s lowercaseString ];
            if ([ s1 rangeOfString:@"bold" ].location != NSNotFound &&
                ( [ s1 rangeOfString:@"italic" ].location != NSNotFound || [ s1 rangeOfString:@"oblique" ].location != NSNotFound )) {
                return [ UIFont fontWithName:s size:render->state->fontSize ];
            }
        }
    }
    if ( isBold ) {
        for ( NSString *s in fonts ) {
            NSString *s1 = [ s lowercaseString ];
            if ([ s1 rangeOfString:@"bold" ].location != NSNotFound &&
                ( [ s1 rangeOfString:@"italic" ].location == NSNotFound && [ s1 rangeOfString:@"oblique" ].location == NSNotFound )) {
                return [ UIFont fontWithName:s size:render->state->fontSize ];
            }
        }
    }
    if ( isItalic ) {
        for ( NSString *s in fonts ) {
            NSString *s1 = [ s lowercaseString ];
            if ([ s1 rangeOfString:@"bold" ].location == NSNotFound &&
                ( [ s1 rangeOfString:@"italic" ].location != NSNotFound || [ s1 rangeOfString:@"oblique" ].location != NSNotFound )) {
                return [ UIFont fontWithName:s size:render->state->fontSize ];
            }
        }
    }
    return [ UIFont fontWithName:fontName size:render->state->fontSize ];
}

static void _isvgRenderTextGradient( isvg_render_t *render, bool isStroking ) {
	CGContextSaveGState( render->state->context );
    
	svg_gradient_t *gradient = isStroking ? render->state->strokePaint.p.gradient : render->state->fillPaint.p.gradient;
    
	CGAffineTransform gradientTransform = CGAffineTransformMake( gradient->transform[0], gradient->transform[1],
                                                                gradient->transform[2], gradient->transform[3],
                                                                gradient->transform[4], gradient->transform[5] );
    myLog( "\tGradient transform %f, %f, %f, %f, %f, %f", gradient->transform[0], gradient->transform[1],
           gradient->transform[2], gradient->transform[3],
           gradient->transform[4], gradient->transform[5] );
    
	switch ( gradient->units ) {
		case SVG_GRADIENT_UNITS_USER:
			myLog( "\tGradient units user" );
			break;
		case SVG_GRADIENT_UNITS_BBOX:
		{
			CGRect aRect = CGPathGetBoundingBox( render->state->path );
			CGContextTranslateCTM( render->state->context, aRect.origin.x, aRect.origin.y );
			CGContextScaleCTM( render->state->context, aRect.size.width, aRect.size.height );
			myLog( "\tGradient units bbox %f %f, %f %f", aRect.origin.x, aRect.origin.y, aRect.size.width, aRect.size.height );
			render->state->bbox = 1;
		} break;
	}
	
	switch ( gradient->spread ) {
		case SVG_GRADIENT_SPREAD_REFLECT:
			myLog( "\tGradient reflect" );
		case SVG_GRADIENT_SPREAD_REPEAT:
        {
			myLog( "\tGradient repeat" );
            CGRect bounds = CGPathGetBoundingBox( render->state->path );
			switch (gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					double x1, y1, x2, y2;
					
					isvgRenderLengthToPixel( render, &gradient->u.linear.x1, &x1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y1, &y1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.x2, &x2 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y2, &y2 );
					myLog( "\tGradient linear %f %f; %f %f", x1, y1, x2, y2 );
					
					// Expand gradient start & end point to context border
					CGPoint p1 = CGPointMake( x1, y1 );
					CGPoint p2 = CGPointMake( x2, y2 );
					double p1p2 = _isvg2PointsDistance( p1, p1 );
					CGPoint p3, p4;
					_isvgIntersection2PointsWithRect( bounds, p1, p2, &p3, &p4 );
					double d1 = _isvg2PointsDistance( p1, p3 ); // distance between 1st point & 1st expanded point
					double d2 = _isvg2PointsDistance( p2, p3 ); // distance betwwen 2 2nd points
					if ( d1 < d2 ) {
						d2 = _isvg2PointsDistance( p2, p4 );
					} else {
						d1 = _isvg2PointsDistance( p1, p4 );
					}
					// Expand stop points
					CGPoint p12, p22; // 2 expanded points
					
                    int extLocs1 = d1 / p1p2;
					if ( fmod( d1, p1p2 ) > 0 ) extLocs1++;
					d1 = extLocs1 * p1p2;
					if ( d1 > 0 ) _isvgExpandedPoint( p1, p2, &p12, d1 );
                    
					int extLocs2 = d2 / p1p2;
					if ( fmod( d2, p1p2 ) > 0 ) extLocs2++;
                    d2 = extLocs2 * p1p2;
                    if ( d2 > 0 ) _isvgExpandedPoint( p2, p1, &p22, d2 );
                    
					CGGradientRef iGradient;
                    _isvgCreateGradientBrush( gradient, gradient->num_stops + extLocs1 + extLocs2, (( extLocs1 % 2 ) == 1 ), &iGradient );
					
					CGContextDrawLinearGradient( render->state->context, iGradient,
												CGPointApplyAffineTransform( p12, gradientTransform ),
                                                CGPointApplyAffineTransform( p22, gradientTransform ),
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
					myLog( "\tGradient num of stop %d", gradient->num_stops );
					CGGradientRelease( iGradient );
				}
					break;
				case SVG_GRADIENT_RADIAL:
				{
					double cx, cy, r, fx, fy;
					
					isvgRenderLengthToPixel( render, &gradient->u.radial.cx, &cx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.cy, &cy );
					isvgRenderLengthToPixel( render, &gradient->u.radial.r, &r );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fx, &fx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fy, &fy );
					myLog( "\tGradient radical c=%fx%f r=%f f=%fx%f", cx, cy, r, fx, fy );
					
                    CGPoint cornerTL = bounds.origin;
                    CGPoint cornerTR = CGPointMake( bounds.origin.x + bounds.size.width, bounds.origin.y );
                    CGPoint cornerBL = CGPointMake( bounds.origin.x, bounds.origin.y + bounds.size.height );
                    CGPoint cornerBR = CGPointMake( bounds.origin.x + bounds.size.width, bounds.origin.y + bounds.size.height );
                    CGPoint centerP = CGPointMake( cx, cy );
                    double dCTL = _isvg2PointsDistance( centerP, cornerTL );
                    double dCTR = _isvg2PointsDistance( centerP, cornerTR );
                    double dCBL = _isvg2PointsDistance( centerP, cornerBL );
                    double dCBR = _isvg2PointsDistance( centerP, cornerBR );
                    double d = fmax( fmax( dCTL, dCTR ), fmax( dCBL, dCBR ));
                    
                    int extLocs = d / r;
                    if ( fmod( d, r ) > 0 ) extLocs++;
                    d = extLocs * r;
                    
					CGGradientRef iGradient;
                    _isvgCreateGradientBrush( gradient, gradient->num_stops + extLocs, FALSE, &iGradient );
				
					CGContextDrawRadialGradient( render->state->context, iGradient,
                                                CGPointApplyAffineTransform( CGPointMake( fx, fy ), gradientTransform ), 0.0,
                                                CGPointApplyAffineTransform( CGPointMake( cx, cy ), gradientTransform ), d,
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
					myLog( "\tGradient num of stop %d", gradient->num_stops );
					CGGradientRelease( iGradient );
				}	
                    break;
			}
			break;
        }
		default:
			myLog( "\tGradient default" );
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			size_t numLocs = gradient->num_stops;
			CGFloat *locations = malloc( sizeof( CGFloat ) * numLocs );
			CGFloat *components = malloc( sizeof( CGFloat ) * numLocs * 4 );
			for ( int i = 0; i < numLocs; i++ ) {
				svg_gradient_stop_t *stop = &gradient->stops[i];
				locations[i] = ( CGFloat )stop->offset;
				int j = i * 4;
				components[j] = svg_color_get_red( &stop->color ) / 255.0;
				components[j + 1] = svg_color_get_green( &stop->color ) / 255.0;
				components[j + 2] = svg_color_get_blue( &stop->color ) / 255.0;
				components[j + 3] = stop->opacity;
                myLog( "\t\tGradient stop %d at %f color=%x:%f", i, stop->offset, stop->color.rgb, stop->opacity );
			}
			CGGradientRef iGradient = CGGradientCreateWithColorComponents( colorSpace, components, locations, numLocs );
            
			switch (gradient->type) {
				case SVG_GRADIENT_LINEAR:
				{
					double x1, y1, x2, y2;
					
					isvgRenderLengthToPixel( render, &gradient->u.linear.x1, &x1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y1, &y1 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.x2, &x2 );
					isvgRenderLengthToPixel( render, &gradient->u.linear.y2, &y2 );
					myLog( "\tGradient linear %f %f; %f %f", x1, y1, x2, y2 );
					CGContextDrawLinearGradient( render->state->context, iGradient,
												CGPointApplyAffineTransform( CGPointMake( x1, y1 ), gradientTransform ),
                                                CGPointApplyAffineTransform( CGPointMake( x2, y2 ), gradientTransform ),
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
					
				}
					break;
				case SVG_GRADIENT_RADIAL:
				{
					double cx, cy, r, fx, fy;
					
					isvgRenderLengthToPixel( render, &gradient->u.radial.cx, &cx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.cy, &cy );
					isvgRenderLengthToPixel( render, &gradient->u.radial.r, &r );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fx, &fx );
					isvgRenderLengthToPixel( render, &gradient->u.radial.fy, &fy );
					myLog( "\tGradient radical c=%fx%f r=%f f=%fx%f", cx, cy, r, fx, fy );
					CGContextDrawRadialGradient( render->state->context, iGradient,
												CGPointApplyAffineTransform( CGPointMake( fx, fy ), gradientTransform ), 0.0,
                                                CGPointApplyAffineTransform( CGPointMake( cx, cy ), gradientTransform ), r,
												kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation );
				} break;
			}
			myLog( "\tGradient num of stop %d", gradient->num_stops );
			CGGradientRelease( iGradient );
			CGColorSpaceRelease( colorSpace );
			break;
	}
    
	render->state->bbox = 0;
	
	CGContextRestoreGState( render->state->context );
}

static void _isvgMaskForTextGradient( isvg_render_t *render, bool isStroke, NSString *s, UIFont *font, CGPoint location ) {
    UIGraphicsBeginImageContext( CGSizeMake( render->viewportWidth, render->viewportHeight ));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGAffineTransform transform = CGContextGetCTM( render->state->context );
    CGContextConcatCTM( context, transform );
    if ( isStroke ) {
        CGContextSetRGBStrokeColor( render->state->context,
                                   svg_color_get_red( &render->state->strokePaint.p.color ) / 255.0,
                                   svg_color_get_green( &render->state->strokePaint.p.color ) / 255.0,
                                   svg_color_get_blue( &render->state->strokePaint.p.color ) / 255.0,
                                   render->state->opacity * render->state->strokeOpacity );
        CGContextSetTextDrawingMode( render->state->context, kCGTextStroke );
    } else {
        CGContextSetRGBFillColor( render->state->context,
                                 svg_color_get_red( &render->state->fillPaint.p.color ) / 255.0,
                                 svg_color_get_green( &render->state->fillPaint.p.color ) / 255.0,
                                 svg_color_get_blue( &render->state->fillPaint.p.color ) / 255.0,
                                 render->state->opacity * render->state->fillOpacity );
        CGContextSetTextDrawingMode( render->state->context, kCGTextFill );
    }
    [ s drawAtPoint:location withFont:font ];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    transform = CGContextGetCTM( render->state->context );
    transform = CGAffineTransformInvert( transform );
    CGContextConcatCTM( render->state->context, transform );
    CGContextTranslateCTM( render->state->context, 0, render->viewportHeight );
    CGContextScaleCTM( render->state->context, 1.0, -1.0 );
    CGRect clipRect = CGRectMake( 0, 0, render->viewportWidth, render->viewportHeight ); //CGRectApplyAffineTransform( CGRectMake( 0, 0, render->viewportWidth, render->viewportHeight ), transform );
    CGContextClipToMask( render->state->context, clipRect, image.CGImage );
}

static svg_status_t isvgRenderText(void *closure,
							svg_length_t *x,
							svg_length_t *y,
							const char   *utf8) {
	isvg_render_t *render = closure;
    double x1, y1;
    isvgRenderLengthToPixel( render, x, &x1 );
    isvgRenderLengthToPixel( render, y, &y1 );
    myLog("Render text %fx%f %s", x1, y1, utf8);
    NSString *s = [ NSString stringWithUTF8String:utf8 ];
    UIFont *font = _isvgSelectFont( render );
    CGSize txtSize = [ s sizeWithFont:font ];
    switch ( render->state->fillPaint.type ) {
        case SVG_PAINT_TYPE_NONE:
            
            break;
        case SVG_PAINT_TYPE_COLOR:
            CGContextSetRGBFillColor( render->state->context,
                                     svg_color_get_red( &render->state->fillPaint.p.color ) / 255.0,
                                     svg_color_get_green( &render->state->fillPaint.p.color ) / 255.0,
                                     svg_color_get_blue( &render->state->fillPaint.p.color ) / 255.0,
                                     render->state->opacity * render->state->fillOpacity );
            CGContextSetTextDrawingMode( render->state->context, kCGTextFill );
            [ s drawAtPoint:CGPointMake( x1, y1 - txtSize.height ) withFont:font ];
            break;
        case SVG_PAINT_TYPE_PATTERN:
            // Ignore
            break;
        case SVG_PAINT_TYPE_GRADIENT:
            _isvgMaskForTextGradient( render, FALSE, s, font, CGPointMake( x1, y1 - txtSize.height ));
            _isvgRenderTextGradient( render, FALSE );
            break;
    }
    switch ( render->state->strokePaint.type ) {
        case SVG_PAINT_TYPE_NONE:
            
            break;
        case SVG_PAINT_TYPE_COLOR:
            CGContextSetRGBStrokeColor( render->state->context,
                                       svg_color_get_red( &render->state->strokePaint.p.color ) / 255.0,
                                       svg_color_get_green( &render->state->strokePaint.p.color ) / 255.0,
                                       svg_color_get_blue( &render->state->strokePaint.p.color ) / 255.0,
                                       render->state->opacity * render->state->strokeOpacity );
            CGContextSetTextDrawingMode( render->state->context, kCGTextStroke );
            [ s drawAtPoint:CGPointMake( x1, y1 - txtSize.height ) withFont:font ];
            break;
        case SVG_PAINT_TYPE_PATTERN:
            // Ignore
            break;
        case SVG_PAINT_TYPE_GRADIENT:
            _isvgMaskForTextGradient( render, TRUE, s, font, CGPointMake( x1, y1 - txtSize.height ));
            _isvgRenderTextGradient( render, TRUE );
            break;
    }
    return SVG_STATUS_SUCCESS;
}

static UIImage *_isvgRenderCImage(unsigned char *data, unsigned int data_width, unsigned int data_height) {
    UIGraphicsBeginImageContext( CGSizeMake( data_width, data_height ));
    CGContextRef context = UIGraphicsGetCurrentContext();
    for ( int i = 0; i < data_height; i++ ) {
        for ( int j = 0; j < data_width; j++ ) {
            int k = 4 * ( i * data_width + j );
            CGContextSetRGBFillColor( context, data[k + 2] / 255.0, data[k + 1] / 255.0, data[k] / 255.0, data[k + 3] / 255.0 );
            CGContextFillRect( context, CGRectMake( j, i, 1.0, 1.0 ));
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

static svg_status_t isvgRenderImage(void		 *closure,
							 unsigned char	*data,
							 unsigned int	 data_width,
							 unsigned int	 data_height,
							 svg_length_t	 *x,
							 svg_length_t	 *y,
							 svg_length_t	 *width,
							 svg_length_t	 *height) {
	isvg_render_t *render = closure;
    double x1, y1, w, h;
    isvgRenderLengthToPixel( render, x, &x1 );
    isvgRenderLengthToPixel( render, y, &y1 );
    isvgRenderLengthToPixel( render, width, &w );
    isvgRenderLengthToPixel( render, height, &h );
    myLog("Render image %fx%f %fx%f : %dx%d", x->value, y->value, width->value, height->value, data_width, data_height );
    UIImage *image = _isvgRenderCImage( data, data_width, data_height );
    [ image drawInRect:CGRectMake( x1, y1, w, h )];
    return SVG_STATUS_SUCCESS;
}

#pragma mark - Render

static svg_render_engine_t ISVG_RENDER_ENGINE = {
	isvgBeginGroup,
    isvgBeginElement,
    isvgEndElement,
    isvgEndGroup,
    isvgMoveTo,
    isvgLineTo,
    isvgCurveTo,
    isvgQuadraticCurveTo,
    isvgArcTo,
    isvgClosePath,
    isvgSetColor,
    isvgSetFillOpacity,
    isvgSetFillPaint,
    isvgSetFillRule,
    isvgSetFontFamily,
    isvgSetFontSize,
    isvgSetFontStyle,
    isvgSetFontWeight,
    isvgSetOpacity,
    isvgSetStrokeDashArray,
    isvgSetStrokeDashOffset,
    isvgSetStrokeLineCap,
    isvgSetStrokeLineJoin,
    isvgSetStrokeMiterLimit,
    isvgSetStrokeOpacity,
    isvgSetStrokePaint,
    isvgSetStrokeWidth,
    isvgSetTextAnchor,
    isvgTransform,
    isvgApplyViewBox,
    isvgSetViewportDimension,
    isvgRenderLine,
    isvgRenderPath,
    isvgRenderEllipse,
    isvgRenderRect,
    isvgRenderText,
    isvgRenderImage
};

bool isvgRenderSvg(svg_t *svg, isvg_render_t *render) {
	svg_status_t status = svg_render( svg, &ISVG_RENDER_ENGINE, render );
	if ( status != SVG_STATUS_SUCCESS ) {
		printf( "ISVG failed to render with error %d\n", status );
		return FALSE;
	}
    return TRUE;
}

bool isvgNewRenderEngineWithFile( svg_t **svg, const char *filePath ) {
    svg_status_t status = svg_create( svg );
	if ( status != SVG_STATUS_SUCCESS ) {
		printf( "ISVG failed to create svg engine with error %d\n", status );
        svg_destroy( *svg );
		return FALSE;
	}
	status = svg_parse( *svg, filePath );
	if ( status != SVG_STATUS_SUCCESS ) {
		printf( "ISVG failed to parse %s with error %d\n", filePath, status );
        svg_destroy( *svg );
		return FALSE;
	}
    return TRUE;
}

bool isvgNewRenderEngineWithData( svg_t **svg, const void *data, size_t length ) {
    svg_status_t status = svg_create( svg );
	if ( status != SVG_STATUS_SUCCESS ) {
		printf( "ISVG failed to create svg engine with error %d\n", status );
        svg_destroy( *svg );
		return FALSE;
	}
	status = svg_parse_buffer( *svg, data, length );
	if ( status != SVG_STATUS_SUCCESS ) {
		printf( "ISVG failed to parse buffer with error %d\n", status );
        svg_destroy( *svg );
		return FALSE;
	}
    return TRUE;
}