#pragma once

#include "Include.h"
#include "VBO.h"

struct VAO {
	GLuint ID;

	VAO() {};

	void LinkAttrib(VBO& VBO, GLuint layout, GLuint numComponents, GLenum type, GLsizeiptr stride, void* offset);

	void Init();
	void Bind();
	void Unbind();
	void Delete();
};