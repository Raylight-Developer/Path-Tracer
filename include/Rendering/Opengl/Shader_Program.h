#pragma once

#include "Include.h"

struct Shader_Program {
	GLuint ID;
	string frag_source;
	string program_name;

	Shader_Program(const string& i_name = "") { ID = 0; program_name = i_name; };

	void f_compile();
	void f_checkCompilation(const GLuint& i_shader, const string& i_shader_name);

	string f_loadFromFile(const string& i_filename);

	void f_init(const char* i_fragmentFile);
	void f_activate();
	void f_delete();
};