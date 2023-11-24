#pragma once

#include "Include.h"

struct Lace;

struct S { //------------Add Space(s) to Lace------------
	uint16 spaces;
	S(const uint16& spaces = 1) : spaces(spaces) {};
	friend Lace& operator<<(Lace& i_lace, const S& i_val);
};

struct NL { //------------Add New Line(s) and/or Global Tab To Lace------------
	uint16 lines;
	bool tabbed;
	NL(const uint16& i_new_lines = 1, const bool& i_use_global_tabs = true) : lines(i_new_lines), tabbed(i_use_global_tabs) {}
	friend Lace& operator<<(Lace& i_lace, const NL& i_val);
};

struct TAB { //------------Add Tab(s) to Lace------------
	uint16 tabs;
	TAB(const uint16& tabs = 1) : tabs(tabs) {}
	friend Lace& operator<<(Lace& i_lace, const TAB& i_val);
};

struct Lace { //------------Utility for string manipulation------------
	stringstream data;
	uint16 current_tab = 0; // Global Tabbing to be transferred through new lines

	Lace();

	Lace& pop(uint16& i_count);
	Lace& operator<< (const Lace& i_value);
	Lace& operator>> (const Lace& i_value);

	Lace& operator+= (const uint16& i_value);
	Lace& operator-= (const uint16& i_value);

	string str() const;

	// Feed directly
	Lace& operator<< (const bool& i_value);
	Lace& operator<< (const char* i_value);
	Lace& operator<< (const float& i_value);
	Lace& operator<< (const double& i_value);
	Lace& operator<< (const string& i_value);
	Lace& operator<< (const stringstream& i_value);

	Lace& operator<< (const int8& i_value);
	Lace& operator<< (const int16& i_value);
	Lace& operator<< (const int32& i_value);
	Lace& operator<< (const int64& i_value);
	Lace& operator<< (const uint8& i_value);
	Lace& operator<< (const uint16& i_value);
	Lace& operator<< (const uint32& i_value);
	Lace& operator<< (const uint64& i_value);
	Lace& operator<< (const ivec2& i_value);
	Lace& operator<< (const ivec3& i_value);
	Lace& operator<< (const ivec4& i_value);
	Lace& operator<< (const uvec2& i_value);
	Lace& operator<< (const uvec3& i_value);
	Lace& operator<< (const uvec4& i_value);
	Lace& operator<< (const vec2& i_value);
	Lace& operator<< (const vec3& i_value);
	Lace& operator<< (const vec4& i_value);
	Lace& operator<< (const quat& i_value);
	Lace& operator<< (const mat2& i_value);
	Lace& operator<< (const mat3& i_value);
	Lace& operator<< (const mat4& i_value);

	// Feed Single Units With Space Before
	Lace& operator>> (const bool& i_value);
	Lace& operator>> (const char* i_value);
	Lace& operator>> (const float& i_value);
	Lace& operator>> (const double& i_value);
	Lace& operator>> (const int8& i_value);
	Lace& operator>> (const int16& i_value);
	Lace& operator>> (const int32& i_value);
	Lace& operator>> (const int64& i_value);
	Lace& operator>> (const uint8& i_value);
	Lace& operator>> (const uint16& i_value);
	Lace& operator>> (const uint32& i_value);
	Lace& operator>> (const uint64& i_value);

	// Vectors
	Lace& operator<< (const vector<string>& i_value);

	static vec3 f_readVec3(const vector<string>& i_data, const uint8& i_offset);
	static mat4 f_readMat4(const vector<string>& i_data, const uint8& i_offset);
};