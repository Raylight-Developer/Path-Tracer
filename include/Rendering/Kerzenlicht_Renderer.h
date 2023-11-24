#pragma once

#include "Include.h"

struct Kerzenlicht_Renderer {
	//File file;

	uvec2 resolution;

	float* render_data;
	float* display_data;

	Kerzenlicht_Renderer();

	void f_updateDisplay(GLuint& ID);
	void f_bindDisplay(GLuint& ID, GLuint& program);
};