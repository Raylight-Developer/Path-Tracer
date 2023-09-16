#pragma once

#include "Include.h"

struct FBO {
	GLuint ID;

	FBO() { ID = 0; };

	void f_init();
	void f_bind();
	void f_unbind();
	void f_delete();
};