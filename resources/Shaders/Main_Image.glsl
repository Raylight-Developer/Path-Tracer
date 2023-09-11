#version 460 core

uniform float iTime;
uniform int iFrame;
uniform vec2 iResolution;

uniform sampler2D iRawFrame;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

void main() {
	vec4 accumulation = texture(iRawFrame, fragTexCoord);
	fragColor = vec4((accumulation.xyz / accumulation.w) * 0.05, 1);
	//fragColor = texture(iRawFrame, fragTexCoord);
}