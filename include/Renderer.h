#pragma once

#include "Include.h"

#include "VAO.h"
#include "VBO.h"
#include "EBO.h"
#include "FBO.h"
#include "FBT.h"
#include "Shader.h"
#include "Texture.h"

struct Renderer {
	vector<GLfloat> vertices;
	vector<GLuint> faces;
	uint16_t iResolution_x;
	uint16_t iResolution_y;
	size_t iFrame;
	double iTime;
	bool pause = false;
	bool frame_advance = false;

	VAO VAO_main;
	VBO VBO_main;
	EBO Faces;
	FBT buffer_tex_a, last_frame_tex;
	FBO FBO_main;
	Shader_Program Buffer_A;
	Shader_Program Main_Image;

	Renderer();

	void recompile();
	void Init();

	static void framebuffer_size_callback(GLFWwindow* window, int width, int height);
	static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods);
};