#pragma once

#include "Include.h"

struct FBT {
	GLuint ID;

	FBT() { ID = 0; };

	void f_resize(const uvec2& i_size);

	void f_init(const uvec2& i_size);
	void f_bind(const GLenum& i_texture_id);
	void f_unbind();
	void f_delete();
};