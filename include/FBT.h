#pragma once

#include "Include.h"

struct FBT {
	GLuint ID;

	FBT() {};

	void Init(const uvec2& i_size);

	void Resize(const uvec2& i_size);
	void Bind(const GLenum& i_texture_id);
	void Unbind();
	void Delete();
};