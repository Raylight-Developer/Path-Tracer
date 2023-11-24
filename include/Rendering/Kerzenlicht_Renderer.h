#pragma once

#include "Include.h"

struct Kerzenlicht_Renderer {
	//File file;

	uvec2 resolution;
	float* render_data;
	float* display_data;

	Kerzenlicht_Renderer();

	void f_resize(const uint16& i_x, const uint16& i_y);
	void f_drawPixel(const uint16& i_x, const uint16& i_y, const fvec4& i_color);
	void f_drawPixel(const uvec2& i_pixel, const fvec4& i_color);
	void f_updateDisplay(GLuint& ID);
	void f_bindDisplay(GLuint& ID, GLuint& program);
};