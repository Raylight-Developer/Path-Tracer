#pragma once

#include "Include.h"

struct VBO {
	GLuint ID;

	VBO() {};

	void Init(GLfloat* vertices, GLsizeiptr size);
	void Bind();
	void Unbind();
	void Delete();
};