#pragma once

#include "Include.h"
#include "I-O/File.h"

struct Texture {
	GLuint ID;

	Texture() { ID = 0; };

	void f_init(const string& i_image_path);
	void f_bind(const GLenum& i_texture_id);
	void f_unbind();
	void f_delete();
};