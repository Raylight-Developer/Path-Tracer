#version 460 core

uniform float iTime;
uniform uint  iFrame;
uniform uint  iRenderMode;
uniform bool  iCameraChange;

uniform sampler2D iRawFrame;
uniform sampler2D iLastFrame;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

void main() {
	float weight = 1.0 / float(iFrame);
	if (iFrame <= 1 || !iCameraChange) {
		fragColor = vec4((texture(iLastFrame, fragTexCoord).rgb * (1 - weight) + texture(iRawFrame, fragTexCoord).rgb)* weight, 1.0);
	}
	else {
		fragColor = texture(iRawFrame, fragTexCoord);
	}
}