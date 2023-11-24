#version 460 core

uniform sampler2D render_output;

in vec2 fragCoord;
in vec2 fragTexCoord;

out vec4 fragColor;

void main() {
	fragColor = texture(render_output, fragTexCoord);
}