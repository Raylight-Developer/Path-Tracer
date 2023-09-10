#pragma once

#include "Include.h"

struct FBO {
	GLuint ID;

	FBO() {};

	void Init();

	void Bind();
	void Unbind();
	void Delete();
};