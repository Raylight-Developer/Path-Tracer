#pragma once

#include "Include.h"

struct EBO {
	GLuint ID;

	EBO() {};

	void Init(GLuint* indices, GLsizeiptr size);
	void Bind();
	void Unbind();
	void Delete();
};