#include "Math/Ops.h"

float fastInvSqrt(const float& number) {
	long i;
	float x2, y;
	const float threehalfs = 1.5F;
	x2 = number * 0.5F;
	y = number;
	i = *(long*)&y;							// get bits for floating value
	i = 0x5f3759df - (i >> 1);				// gives initial guess y0
	y = *(float*)&i;						// convert bits back to float
	y = y * (threehalfs - (x2 * y * y));	// Newton step, repeating increases accuracy
	y = y * (threehalfs - (x2 * y * y));
	y = y * (threehalfs - (x2 * y * y));
	return y;
}

vector<string> splitString(const string& input, const string& delimiter) {
	vector<string> tokens;
	string::size_type start = 0;
	string::size_type end = input.find(delimiter);
	while (end != string::npos) {
		tokens.push_back(input.substr(start, end - start));
		start = end + 1;
		end = input.find(delimiter, start);
	}
	tokens.push_back(input.substr(start));
	return tokens;
}
vector<string> splitString(const string& input) {
	vector<string> result;
	istringstream iss(input);
	string token;
	while (iss >> token) {
		result.push_back(token);
	}
	return result;
}
string strEnd(const vector<string>& P_Vec, const size_t& P_Start) {
	return accumulate(P_Vec.begin() + P_Start, P_Vec.end(), string());
}
string strEndSpace(const vector<string>& P_Vec, const size_t& P_Start) {
	return accumulate(
		P_Vec.begin() + P_Start, P_Vec.end(), string(),
		[](const string& accumulator, const string& current) {
			return accumulator.empty() ? current : accumulator + " " + current;
		}
	);
}
string strSpaced(const vector<size_t>& P_Vec) {
	std::ostringstream oss;
	for (size_t i = 0; i < P_Vec.size(); ++i) {
		oss << P_Vec[i];
		if (i < P_Vec.size() - 1) {
			oss << " ";
		}
	}
	return oss.str();
}

string vecToStringLines(const vector<string>& P_Vec) {
	if (P_Vec.empty()) return "";
	string Result = P_Vec[0];
	for (size_t i = 1; i < P_Vec.size(); ++i) {
		Result += "\n";
		Result += P_Vec[i];
	}
	return Result;
}

vector<string> splitStringToLines(const string& P_Lines) {
	vector<string> lines;
	istringstream iss(P_Lines);
	string line;
	while (getline(iss, line)) {
		lines.push_back(line);
	}
	return lines;
}
string addTabsToStr(const string& input, const int& tabs) {
	istringstream iss(input);
	ostringstream oss;
	string line;
	while (getline(iss, line)) {
		int Tab = tabs;
		while (Tab--) {
			oss << "\t";
		}
		oss << line << "\n";
	}
	return oss.str().substr(0, oss.str().length() - 1);
}

double clamp(const double& P_Value, const double& P_Min, const double& P_Max) {
	if (P_Value >= P_Min && P_Value <= P_Max) return P_Value;
	else if (P_Value < P_Min) return P_Min;
	else return P_Max;
}

double rand(const double& a, const double& b) {
	return mix(a, b, double(rand()));
}

double sign(const double& input) {
	return (input > 0.0) - (input < 0.0);
}

double mix(const double& P_inputA, const double& P_inputB, const double& P_factor) {
	return P_inputA + P_factor * (P_inputB - P_inputA);
}

double cross(const dvec2& i_a, const dvec2& i_b) {
	return i_a.x * i_b.y - i_a.y * i_b.x;
}


vector<char> readFile(const string& i_file_path) {
	ifstream file(i_file_path, ios::ate | ios::binary);

	if (!file.is_open()) {
		Lace err;
		throw runtime_error((err << "!!ERROR!! Failed To Open File: " << i_file_path).str());
	}

	size_t fileSize = (size_t)file.tellg();
	vector<char> buffer(fileSize);

	file.seekg(0);
	file.read(buffer.data(), fileSize);

	file.close();

	return buffer;
}

mat3 f_eulerToRotationMatrix(const vec3& i_value) {
	const vec1 pi = i_value.x * DEG_RAD;
	const vec1 ya = i_value.y * DEG_RAD;
	const vec1 ro = i_value.z * DEG_RAD;

	const mat4 rollMat = mat4(
		cos(ro), -sin(ro), 0, 0,
		sin(ro), cos(ro), 0, 0,
		0, 0, 1, 0,
		0, 0, 0, 1
	);

	const mat4 yawMat = mat4(
		cos(ya), 0, sin(ya), 0,
		0, 1, 0, 0,
		-sin(ya), 0, cos(ya), 0,
		0, 0, 0, 1
	);

	const mat4 pitchMat = mat4(
		1, 0, 0, 0,
		0, cos(pi), -sin(pi), 0,
		0, sin(pi), cos(pi), 0,
		0, 0, 0, 1
	);

	return mat3(rollMat * yawMat * pitchMat);
}

vector<string> f_splitString(const string& i_value, const string& i_delimiter) {
	vector<string> tokens;
	string::size_type start = 0;
	string::size_type end = i_value.find(i_delimiter);
	while (end != string::npos) {
		tokens.push_back(i_value.substr(start, end - start));
		start = end + 1;
		end = i_value.find(i_delimiter, start);
	}
	tokens.push_back(i_value.substr(start));
	return tokens;
}

string f_mergeToString(const vector<string>& i_value, const size_t& i_start_item, const string& i_separator) {
	return accumulate(
		i_value.begin() + i_start_item, i_value.end(), string(),
		[i_separator](const string& accumulator, const string& current) {
			return accumulator.empty() ? current : accumulator + i_separator + current;
		}
	);
}