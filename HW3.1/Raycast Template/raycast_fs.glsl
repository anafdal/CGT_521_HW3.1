#version 430

layout(location = 1) uniform int pass;
layout(location = 3) uniform int mode = 0;
layout(location = 6) uniform float time;
layout(location = 7) uniform vec4 slider;
layout(location = 8) uniform int scene = 0;

layout(binding = 0) uniform sampler2D backfaces_tex;

layout(location = 0) out vec4 fragcolor;  
         
in vec3 vpos;  

//forward function declarations
vec4 raytracedcolor(vec3 rayStart, vec3 rayStop);
vec4 clear_color(vec3 rayDir);
vec4 lighting(vec3 pos, vec3 rayDir);
float distToShape(vec3 pos);
vec3 normal(vec3 pos);
vec4 clear_color2(vec3 rayDir);
float shadow( in vec3 ro, in vec3 rd, float mint, float maxt );
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w );

const vec3 light_pos = vec3(0.0, 2.0, 5.0);


const vec4 La = vec4(0.75, 0.75, 0.75, 1.0);
const vec4 Ld = vec4(0.74, 0.74, 0.74, 1.0);
const vec4 Ls = vec4(1.0, 1.0, 0.74, 1.0);

const vec4 Ka = vec4(0.4, 0.4, 0.34, 1.0);
const vec4 Kd = vec4(1.0, 1.0, 0.73, 1.0);
const vec4 Ks = vec4(0.1, 0.1, 0.073, 1.0);


void main(void)
{   
	if(pass == 1)
	{
		  fragcolor = vec4((vpos), 1.0); //write cube positions to texture
		
		
	}
	else if(pass == 2) 
	{
		if(mode == 0) // for debugging: show backface colors
		{
			fragcolor = texelFetch(backfaces_tex, ivec2(gl_FragCoord), 0);
			return;
		}
		else if(mode == 1) // for debugging: show frontface colors
		{
			fragcolor = vec4((vpos), 1.0);
			return;
		}
		else // raycast
		{
			vec3 rayStart = vpos.xyz;
			vec3 rayStop = texelFetch(backfaces_tex, ivec2(gl_FragCoord.xy), 0).xyz;
			fragcolor = raytracedcolor(rayStart, rayStop);
		}
	}

	

}
          

// trace rays until they intersect the surface
vec4 raytracedcolor(vec3 rayStart, vec3 rayStop)
{
	const int MaxSamples = 1000; //max number of steps along ray

	vec3 rayDir = normalize(rayStop-rayStart);	//ray direction unit vector
	float travel = distance(rayStop, rayStart);	
	float stepSize = travel/MaxSamples;	//initial raymarch step size
	vec3 pos = rayStart;				//position along the ray
	vec3 step = rayDir*stepSize;		//displacement vector along ray
	
	for (int i=0; i < MaxSamples && travel > 0.0; ++i, pos += step, travel -= stepSize)
	{
		float dist = distToShape(pos); //How far are we from the shape we are raycasting?

		//Distance tells us how far we can safely step along ray without intersecting surface
		stepSize = dist;
		step = rayDir*stepSize;
		
		//Check distance, and if we are close then perform lighting
		const float eps = 1e-4;
		if(dist <= eps)
		{
			return lighting(pos, rayDir);
		    
		}	
	}
	//If the ray never intersects the scene then output clear color
	return mix(clear_color2(rayDir),clear_color(rayDir),cos(time));
}

//Compute lighting on the raycast surface using Phong lighting model
vec4 lighting(vec3 pos, vec3 rayDir)
{
	const vec3 light = normalize(light_pos-pos); //light direction from surface
	vec3 n = normal(pos);

	vec4 La = clear_color(n);
	float diff = max(0.0, dot(n, light));
	float s= shadow( pos, light, 0.01, 2 );/////////////////////////////////////////////////////////shadow
	//float s=softshadow( pos, light, 0.000001, 2,1/18 );
	return La*Ka + Ld*Kd*diff*s;	
}

vec4 clear_color(vec3 rayDir)
{
	const vec4 color1 = vec4(0.6, 0.8, 0.9, 1.0);
	return color1;
}
vec4 clear_color2(vec3 rayDir)//////////////////////////////////////used for the mix background
{
	const vec4 color2 = vec4(1.0, 0.0, 0.0, 1.0);
	return color2;
}

//shape function declarations
float sdSphere( vec3 p, float s );
float sdBox( vec3 p, vec3 b );
float sdRoundBox( vec3 p, vec3 b, float r );//////
float sdHexPrism( vec3 p, vec2 h );//////
float sdTorus( vec3 p, vec2 t );//////
float sdCone( vec3 p, vec2 c );/////////
float sdOctahedron( vec3 p, float s);
float opSubtraction( float d1, float d2 );
float opIntersection( float d1, float d2 );
float shadow( in vec3 ro, in vec3 rd, float mint, float maxt );
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w );

// For more distance functions see
// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

// Soft shadows
// http://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm

// WebGL example and a simple ambient occlusion approximation
// https://www.shadertoy.com/view/Xds3zN


//distance to the shape we are drawing
float distToShape(vec3 pos)
{
 if(scene == 0)//scene 0
	{
		const float radius = 0.4;
		//vec3 c = vec3(1.0, 1.0, 1.0) + 2.0*slider.xyz;
		//vec3 q = mod(pos,c)-0.5*c;
		float d0=sdRoundBox(pos+vec3(0.0, 0.0, 0.0), vec3(0.4, 0.4, 0.4),radius*time);///////round box and it animates with time
		//float d0 = sdSphere(q, radius);
		return d0;
	}
	

	else if(scene == 1)//scene 1
	{
		
        const float radius = 0.4;
		vec3 offset = 2.0*slider.xyz;
		//float d1 = sdSphere(pos+offset, radius*slider.w);
		float d1=sdTorus(pos+offset, vec2(0.2, 0.2)*slider.w);//donut/torus shape that changes with slider
		return d1;


	}
	else if(scene == 2)//scene 2
	{	const float radius = 0.2;
		//float d2 = sdBox(pos+vec3(0.0, 0.0, 0.0), vec3(0.4, 0.4, 0.4));
		//float d2=sdHexPrism( pos+vec3(0.0, 0.0, 0.0),vec2(0.4, 0.4));///hex prism

		//float d1=sdOctahedron(pos+vec3(0.0, 0.0, 0.0), 1.5);
		//float d2=softshadow(pos, light_pos, 0, 5.0, 1/8 );
		//float d2= shadow(pos, light_pos, 0.01, 1000.0);
		//return min(d1,d2);
		//return d2;
		//return d1;
		float d1=sdSphere(pos+vec3(0.0, 0.0, -1.0),radius);
		float d2=sdBox(pos+vec3(0.0, 0.0, 0.0),vec3(5.0,5.0,0.1));
		float d3=min(d1,d2);
		return d3;

	}
	else if (scene==3)///////////////////////////////////////////////new scene with combination of 3 primitives
	{
	    //float d2 = sdBox(pos+vec3(0.0, 0.0, 0.0), vec3(0.4, 0.4, 0.4));
		float d1=sdHexPrism( pos+vec3(0.0, 0.0, 0.0),vec2(0.2, 0.8));
		float d2= sdCone( pos+vec3(0.0, 0.3, 0.0)*slider.w, vec2(0.2, 0.2) );/////cone with hex prism hole
		float d3=opSubtraction(d1,d2 );
		float d4=sdOctahedron(pos+vec3(0.0, 0.0, 0.0), 1.0);
		float d5=opIntersection( d3, d4 );
		return d5;
		//return d3;
	}

	
}

// shape function definitions            
float sdSphere( vec3 p, float s )
{
	return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdRoundBox( vec3 p, vec3 b, float r )//round box//////////////////////////////////////////////////////////////////////////
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}
float sdHexPrism( vec3 p, vec2 h )//////////////////////////////////////hexagonal prism
{
  const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
  p = abs(p);
  p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
  vec2 d = vec2(
       length(p.xy-vec2(clamp(p.x,-k.z*h.x,k.z*h.x), h.x))*sign(p.y-h.x),
       p.z-h.y );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
float sdTorus( vec3 p, vec2 t )/////////////////////////////////////////////////////torus
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float sdCone( vec3 p, vec2 c )//////////////////////////////////////////cone
{
  // c is the sin/cos of the angle
  float q = length(p.xy);
  return dot(c,vec2(q,p.z));
}
float sdOctahedron( vec3 p, float s)////////////////////octohedron
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  vec3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(vec3(q.x,q.y-s+k,q.z-k)); 
}
float sdCylinder(vec3 p, float h, float r)////////////////cylinder
{
    vec2 q = vec2( length(p.xz)-r, abs(p.y-h*0.5)-h*0.5 );
    return min( max(q.x,q.y),0.0) + length(max(q,0.0));
}
float sdPlane( vec3 p )
{
	return p.y;
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }//subtraction
float opIntersection( float d1, float d2 ) { return max(d1,d2); }//intersection

//float map(vec3 p) { return length(p); }


///////////////////////////////////////////////////////////////////////////////////////////////////////////


float shadow( in vec3 ro, in vec3 rd, float mint, float maxt )
{
    for( float t=mint; t<maxt; )
    {
        float h = distToShape(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        t += h;
    }
    return 1.0;
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w )
{
    float s = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = distToShape(ro + rd*t);///this needs to be distShape
        s = min( s, 0.5+0.5*h/(w*t) );
        if( s<0.0 ) break;
        t += h;
    }
    s = max(s,0.0);
    return s*s*(3.0-2.0*s); // smoothstep
}


//normal vector of the shape we are drawing.
//Estimated as the gradient of the signed distance function.
vec3 normal(vec3 pos)
{
	const float h = 0.001;
	const vec3 Xh = vec3(h, 0.0, 0.0);	
	const vec3 Yh = vec3(0.0, h, 0.0);	
	const vec3 Zh = vec3(0.0, 0.0, h);	

	return normalize(vec3(distToShape(pos+Xh)-distToShape(pos-Xh), distToShape(pos+Yh)-distToShape(pos-Yh), distToShape(pos+Zh)-distToShape(pos-Zh)));
}


