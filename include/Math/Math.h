#pragma once

#include "Lace.h"

struct Math {
	static float fastInvSqrt(const float& i_value);

	static string strSpaced(const vector<size_t>& P_Vec);
	static string vecToStringLines(const vector<string>& P_Vec);
	static string addTabsToStr(const string& input, const int& tabs);
	static string strEnd(const vector<string>& P_Vec, const size_t& P_Start);
	static string strEndSpace(const vector<string>& P_Vec, const size_t& P_Start);

	static vector<string> splitString(const string& input);
	static vector<string> splitStringToLines(const string& P_Lines);
	static vector<string> splitString(const string& input, const string& delimiter);

	static double sign(const double& input);
	static double rand(const double& a, const double& b);
	static double clamp(const double& P_Value, const double& P_Min, const double& P_Max);
	static double mix(const double& P_inputA, const double& P_inputB, const double& P_factor);
};