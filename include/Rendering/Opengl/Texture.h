#pragma once

#include "Include.h"

struct Texture {
	GLuint ID;

	Texture() { ID = 0; };

	void f_init(const string& i_image_path, const File_Extension::Enum& i_type);
	void f_bind(const GLenum& i_texture_id);
	void f_unbind();
	void f_delete();
};