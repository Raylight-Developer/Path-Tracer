#pragma once

#include "Include.h"

struct EBO {
	GLuint ID;

	EBO() { ID = 0; };

	void f_init(GLuint* i_indices, GLsizeiptr i_size);
	void f_bind();
	void f_unbind();
	void f_delete();
};