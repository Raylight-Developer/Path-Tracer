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

#define GAMMA 0.4
#define BRIGHTNESS 0.8

void main() {
	// vec4 col = texture(iRawFrame, fragTexCoord);
	// col *= BRIGHTNESS;
	// col = vec4(pow(col.x, GAMMA), pow(col.y, GAMMA), pow(col.z, GAMMA), pow(col.w, GAMMA));
	// fragColor = col * 1.3;

	fragColor = texture(iAccumulationFrame, fragTexCoord);
}