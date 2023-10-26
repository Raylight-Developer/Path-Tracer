#pragma once

#include "Include.h"

struct Lace {
	stringstream string_data;
	int current_tab = 0;

	Lace();

	Lace& setTab(const int& P_Tab);
	Lace& nlTab(const int& P_Tab = 0);
	Lace& nl(const int& P_lines = 1);

	// Feed directly
	Lace& operator<< (const stringstream& i_value);
	Lace& operator<< (const bool& i_value);
	Lace& operator<< (const float& i_value);
	Lace& operator<< (const double& i_value);
	Lace& operator<< (const string& i_value);
	Lace& operator<< (const char* i_value);
	Lace& operator<< (const int& i_value);
	Lace& operator<< (const uint32_t& i_value);
	Lace& operator<< (const long int& i_value);
	Lace& operator<< (const long long int& i_value);
	Lace& operator<< (const long double& i_value);
	Lace& operator<< (const unsigned long long int& i_value);
	Lace& operator<< (const dvec2& i_value);
	Lace& operator<< (const dvec3& i_value);
	Lace& operator<< (const dvec4& i_value);
	Lace& operator<< (const ivec2& i_value);
	Lace& operator<< (const ivec3& i_value);
	Lace& operator<< (const ivec4& i_value);
	Lace& operator<< (const uvec2& i_value);
	Lace& operator<< (const uvec3& i_value);
	Lace& operator<< (const uvec4& i_value);

	// Feed with space before
	Lace& operator>> (const stringstream& i_value);
	Lace& operator>> (const bool& i_value);
	Lace& operator>> (const float& i_value);
	Lace& operator>> (const double& i_value);
	Lace& operator>> (const string& i_value);
	Lace& operator>> (const char* i_value);
	Lace& operator>> (const int& i_value);
	Lace& operator>> (const uint32_t& i_value);
	Lace& operator>> (const long int& i_value);
	Lace& operator>> (const long long int& i_value);
	Lace& operator>> (const long double& i_value);
	Lace& operator>> (const unsigned long long int& i_value);
	Lace& operator>> (const dvec2& i_value);
	Lace& operator>> (const dvec3& i_value);
	Lace& operator>> (const dvec4& i_value);
	Lace& operator>> (const ivec2& i_value);
	Lace& operator>> (const ivec3& i_value);
	Lace& operator>> (const ivec4& i_value);
	Lace& operator>> (const uvec2& i_value);
	Lace& operator>> (const uvec3& i_value);
	Lace& operator>> (const uvec4& i_value);
	string str() const;
	const char* cstr() const;
};