#pragma once

#include "Include.h"

#include "Object/Camera.h"

#include "EBO.h"
#include "FBO.h"
#include "FBT.h"
#include "VAO.h"
#include "VBO.h"
#include "Texture.h"
#include "Shader_Program.h"

struct Render_Mode {
	enum Enum {
		AMBIENT_OCCLUSION,
		PATHTRACED,
		ZBUFFER
	};
};

inline Render_Mode::Enum switchRenderMode(Render_Mode::Enum i_current) {
	int currentIntValue = static_cast<int>(i_current) + 1;
	if (currentIntValue > 2) return static_cast<Render_Mode::Enum>(0);
	return static_cast<Render_Mode::Enum>(currentIntValue);
}

struct GLSL_Renderer {
	vector<GLfloat> vertices;
	vector<GLuint> faces;

	double iTime;
	size_t iFrame;
	uvec2  iResolution;
	
	Camera camera;
	bool   camera_change;

	// Control Input Variables
	Render_Mode::Enum render_mode;
	double camera_move_sensitivity;
	double camera_view_sensitivity;
	bool   right_mouse_down;
	bool   left_mouse_down;
	dvec2  last_mouse;

	double last_frame_time;
	double frame_time;

	VAO main_vao;
	VBO main_vbo;
	EBO main_ebo;
	FBT buffer_tex_a;
	FBT last_frame_tex;
	FBO main_fbo;
	Shader_Program main_buffer;
	Shader_Program post_buffer;

	bool pause;

	GLSL_Renderer();

	void recompile();
	void f_init();

	static void framebuffer_size_callback(GLFWwindow* window, int width, int height);
	static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos);
	static void mouse_button_callback(GLFWwindow* window, int button, int action, int mods);
	static void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
	static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
};