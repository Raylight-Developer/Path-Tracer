#pragma once

#include "../include/Include.hpp"

struct Texture {
	GLuint ID;

	Texture() {};

	void Init(const int& i_width, const int& i_height);

	void Resize(const int& i_width, const int& i_height);
	void Bind(const GLenum& i_texture_id);
	void Unbind();
	void Delete();
};