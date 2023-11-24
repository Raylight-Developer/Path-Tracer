#pragma once

#include "Include.h"

#include "I-O/File.h"
#include "Render_Kernel.h"

struct Kerzenlicht_Renderer {
	File file;

	float* render_data;
	float* display_data;

	Kerzenlicht_Renderer();

	void f_render();

	void f_resize();

	void f_drawPixel(const uint32& i_x, const uint32& i_y, const fvec4& i_color);
	void f_drawPixel(const uint32& i_x, const uint32& i_y, const fvec3& i_color, const fvec1& i_alpha);

	void f_updateDisplay(GLuint& ID);
	void f_bindDisplay(GLuint& ID, GLuint& program);
};