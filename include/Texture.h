#pragma once

#include "Include.h"

struct Texture {
	GLuint ID;

	Texture() {};

	void Init(const string& i_image_path, const File_Extension::Enum& i_type);

	void Bind(const GLenum& i_texture_id);
	void Unbind();
	void Delete();
};