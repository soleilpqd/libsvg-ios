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

#import "isvgRendererState.h"

svg_status_t isvgRenderStateInit( isvg_render_state_t *state );
svg_status_t isvgRenderStateInitCopy( isvg_render_state_t *state, const isvg_render_state_t *other );
svg_status_t isvgRenderStateDeinit( isvg_render_state_t *state );

svg_status_t isvgRenderStateCreate( isvg_render_state_t **state ) {
    *state = malloc( sizeof( isvg_render_state_t ));
    if ( *state == NULL )
        return SVG_STATUS_NO_MEMORY;
    
    isvgRenderStateInit( *state );
    
    return SVG_STATUS_SUCCESS;
}

svg_status_t isvgRenderStateInit( isvg_render_state_t *state ) {
    /* trust libsvg to set all of these to reasonable defaults:
     state->fill_paint;
     state->stroke_paint;
     state->fill_opacity;
     state->stroke_opacity;
     */
    
    state->fontFamily = strdup( "Helvetica" );
    if ( state->fontFamily == NULL )
        return SVG_STATUS_NO_MEMORY;
    
    state->fontSize = 1.0;
    state->fontStyle = SVG_FONT_STYLE_NORMAL;
    state->fontWeight = 400;
    state->fontDirty = 1;
    
    state->dash = NULL;
    state->numDashes = 0;
    state->dashOffset = 0;
    
    state->opacity = 1.0;
    
    state->bbox = 0;
    
    state->textAnchor = SVG_TEXT_ANCHOR_START;
    
    state->next = NULL;
	state->path = CGPathCreateMutable();
    
    return SVG_STATUS_SUCCESS;
}

svg_status_t isvgRenderStateInitCopy( isvg_render_state_t *state, const isvg_render_state_t *other ) {
    isvgRenderStateDeinit( state );
    if ( other == NULL )
        return isvgRenderStateInit( state );
    *state = *other;
    
    if ( other->fontFamily )
        state->fontFamily = strdup(( char* )other->fontFamily );
    
    state->viewportWidth = other->viewportWidth;
    state->viewportHeight = other->viewportHeight;
	state->path = CGPathCreateMutableCopy( other->path );
    state->context = other->context;
    
    if ( other->dash ) {
        state->dash = malloc( state->numDashes * sizeof( double ));
        if ( state->dash == NULL )
            return SVG_STATUS_NO_MEMORY;
        memcpy( state->dash, other->dash, state->numDashes * sizeof( double ));
    }
    
    return SVG_STATUS_SUCCESS;
}

svg_status_t isvgRenderStateDeinit( isvg_render_state_t *state ) {   
    if ( state->fontFamily ) {
        free( state->fontFamily );
        state->fontFamily = NULL;
    }
    if ( state->dash ) {
        free( state->dash );
        state->dash = NULL;
    }
    state->next = NULL;
	CGPathRelease( state->path );
	state->path = NULL;
    state->context = NULL;
    return SVG_STATUS_SUCCESS;
}

svg_status_t isvgRenderStateDestroy( isvg_render_state_t *state ) {
    isvgRenderStateDeinit( state );
    free( state );
    return SVG_STATUS_SUCCESS;
}

isvg_render_state_t *isvgRenderStatePush( isvg_render_state_t *state ) {
    isvg_render_state_t *new;
    isvgRenderStateCreate( &new );
    if ( new == NULL )
        return NULL;
    isvgRenderStateInitCopy( new, state );
    new->next = state;
    return new;
}

isvg_render_state_t *isvgRenderStatePop( isvg_render_state_t *state ) {
    isvg_render_state_t *next;
    if ( state == NULL )
        return NULL;
    next = state->next;
    isvgRenderStateDestroy( state );
    return next;
}