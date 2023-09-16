#pragma once

#include "Include.h"

struct VBO {
	GLuint ID;

	VBO() { ID = 0; };

	void f_init(GLfloat* vertices, GLsizeiptr size);
	void f_bind();
	void f_unbind();
	void f_delete();
};