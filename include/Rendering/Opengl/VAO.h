#pragma once

#include "Include.h"
#include "VBO.h"

struct VAO {
	GLuint ID;

	VAO() { ID = 0; };

	void f_linkVBO(VBO& VBO, GLuint layout, GLuint numComponents, GLenum type, GLsizei stride, void* offset);

	void f_init();
	void f_bind();
	void f_unbind();
	void f_delete();
};