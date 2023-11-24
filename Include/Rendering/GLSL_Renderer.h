#pragma once

#include "Include.h"

#include "Kerzenlicht_Renderer.h"
#include "Object/Camera.h"

#include "Opengl/EBO.h"
#include "Opengl/FBO.h"
#include "Opengl/FBT.h"
#include "Opengl/VAO.h"
#include "Opengl/VBO.h"
#include "Opengl/Texture.h"
#include "Opengl/Shader_Program.h"

struct GLSL_Renderer {
	uvec2 display_resolution;
	Kerzenlicht_Renderer renderer;

	double camera_move_sensitivity;
	double camera_view_sensitivity;
	vector<bool> keys;
	dvec2  last_mouse;

	double run_time;
	double frame_time;
	double window_time;

	clock_t last_time;
	clock_t current_time;

	VAO main_vao;
	VBO main_vbo;
	EBO main_ebo;
	GLuint display_texture;
	Shader_Program raw_frame_program;

	GLSL_Renderer();

	void f_recompile();
	void f_init();
	void f_exit();

	static void framebuffer_size_callback(GLFWwindow* window, int width, int height);
	static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos);
	static void mouse_button_callback(GLFWwindow* window, int button, int action, int mods);
	static void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
	static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
};