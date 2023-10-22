#version 460 core

uniform float iTime;
uniform uint  iFrame;
uniform vec2  iResolution;
uniform uint  iRenderMode;
uniform bool  iBidirectional;

uniform bool  iCameraChange;

uniform sampler2D iRawFrame;
uniform sampler2D iAccumulationFrame;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

vec3 ACESFilm(vec3 x) {
	float a = 2.51;
	float b = 0.03;
	float c = 2.43;
	float d = 0.59;
	float e = 0.14;
	return (x*(a*x+b))/(x*(c*x+d)+e);
}

const mat3 xyz2rgb = mat3 (
	 3.2404542, -0.9692660,  0.0556434,
	-1.5371385,  1.8760108, -0.2040259,
	-0.4985314,  0.0415560,  1.0572252
);

void main() {
	vec3 x = max(texture(iAccumulationFrame, fragTexCoord).rgb, 0.0);
	float r = floor(log2(iResolution.y) - 4.5) + 0.5;
	fragColor = vec4(ACESFilm(max(xyz2rgb * x, 0.0)), 1.0);
	fragColor = texture(iAccumulationFrame, fragTexCoord);
}