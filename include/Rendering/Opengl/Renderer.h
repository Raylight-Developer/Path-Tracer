#pragma once

#include "Include.h"

#include "Object/Camera.h"

#include "VAO.h"
#include "VBO.h"
#include "EBO.h"
#include "FBO.h"
#include "FBT.h"
#include "Shader_Program.h"
#include "Texture.h"

struct Renderer {
	vector<GLfloat> vertices;
	vector<GLuint> faces;

	double iTime;
	size_t iFrame;
	uvec2 iResolution;
	
	Camera camera;
	bool camera_change;

	// Control Input Variables
	vector<bool> keys;
	double camera_move_sensitivity;
	double camera_view_sensitivity;
	dvec2 last_mouse;

	VAO VAO_main;
	VBO VBO_main;
	EBO Faces;
	FBT buffer_tex_a;
	FBT last_frame_tex;
	FBO FBO_main;
	Shader_Program Buffer_A;
	Shader_Program Main_Image;

	bool pause;

	Renderer();

	void recompile();
	void f_init();

	static void framebuffer_size_callback(GLFWwindow* window, int width, int height);
	static void cursor_position_callback(GLFWwindow* window, double xpos, double ypos);
	static void mouse_button_callback(GLFWwindow* window, int button, int action, int mods);
	static void scroll_callback(GLFWwindow* window, double xoffset, double yoffset);
	static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
};