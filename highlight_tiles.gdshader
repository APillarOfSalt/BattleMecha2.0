shader_type canvas_item;

uniform vec2 offset = vec2(32.0);
uniform float intensity = 5.0;
varying vec2 vert;

void vertex() {
	vert = VERTEX;
}

void fragment() {
	vec2 pos = (vert  * SCREEN_PIXEL_SIZE) - (offset * SCREEN_PIXEL_SIZE);
	vec2 point = vec2(fract(TIME)) * -SCREEN_PIXEL_SIZE;
	float leng = length(point)*length(pos);
	float angle0 = 0.0;
	if(abs(leng) > 0.0);
		angle0 = acos( dot(point,pos) / ( leng ) );
	angle0 = max(0,angle0);
	COLOR.rb = vec2(0.0);
	COLOR.g = angle0/(PI*2.0);
	//COLOR.a = min(COLOR.a, distance(point, pos)*(angle0+(PI*2.0))-(PI*2.0) );
	//COLOR.rb = vec2(0);
	//COLOR.g = angle0;
	//COLOR.a = min(COLOR.a, max(0,max(COLOR.g, angle0)));
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
