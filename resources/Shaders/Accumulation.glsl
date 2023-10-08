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
	float interval = float(iFrame);
	if (iFrame <= 1 || !iCameraChange) {
		fragColor = vec4((texture(iLastFrame, fragTexCoord).xyz * interval + texture(iRawFrame, fragTexCoord).xyz) / (interval + 1.0), 1);
	}
	else {
		fragColor = texture(iRawFrame, fragTexCoord);
	}
}