#pragma once

#include "Include.h"
#include "Lace.h"

string strSpaced(const vector<size_t>& P_Vec);
string vecToStringLines(const vector<string>& P_Vec);
string addTabsToStr(const string& input, const int& tabs);
string strEnd(const vector<string>& P_Vec, const size_t& P_Start);
string strEndSpace(const vector<string>& P_Vec, const size_t& P_Start);
float  fastInvSqrt(const float& i_value);
double sign(const double& input);
double cross(const dvec2& i_a, const dvec2& i_b);
double mix(const double& P_inputA, const double& P_inputB, const double& P_factor);
double rand(const double& a, const double& b);
double clamp(const double& P_Value, const double& P_Min, const double& P_Max);
vector<string> splitString(const string& input);
vector<string> splitStringToLines(const string& P_Lines);
vector<string> splitString(const string& input, const string& delimiter);


//io
vector<char> readFile(const string& i_file_path);

// glm
mat3 f_eulerToRotationMatrix(const vec3& i_value);

// math
float random_float();
float random_float(float min, float max);

// string-tokens
vector<string> f_splitString(const string& i_value, const string& i_delimiter = " ");
string f_mergeToString(const vector<string>& i_value, const size_t& i_start_item = 0, const string& i_separator = "");