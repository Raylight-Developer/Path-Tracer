#include "Math/Lace.h"

Lace::Lace() {
	data = stringstream();
	current_tab = 0;
}

Lace& operator<<(Lace& i_lace, const S& i_val) {
	uint16 spaces = i_val.spaces;
	while (spaces--)
		i_lace << " ";
	return i_lace;
}

Lace& operator<<(Lace& i_lace, const NL& i_val) {
	uint16 lines = i_val.lines;
	uint16 tabs = i_lace.current_tab;
	while (lines--)
		i_lace << "\n";
	if (i_val.tabbed)
		while (tabs--)
			i_lace << "\t";
	return i_lace;
}

Lace& operator<<(Lace& i_lace, const TAB& i_val) {
	uint16 tabs = i_lace.current_tab + i_val.tabs;
	while (tabs--)
		i_lace << "\t";
	return i_lace;
}

Lace& Lace::pop(uint16& i_count) {
	string Result = str();
	while (i_count--) Result.pop_back();
	data << Result;
	return *this;
}

Lace& Lace::operator<<(const Lace& i_value) {
	data << i_value.data.str();
	return *this;
}

Lace& Lace::operator>>(const Lace& i_value) {
	data << " " << i_value.data.str();
	return *this;
}

Lace& Lace::operator+=(const uint16& i_value) {
	current_tab += 1;
	return *this;
}

Lace& Lace::operator-=(const uint16& i_value) {
	current_tab -= 1;
	return *this;
}

string Lace::str() const {
	return data.str();
}

Lace& Lace::operator<< (const stringstream& i_value) {
	data << i_value.str();
	return *this;
}

Lace& Lace::operator<< (const bool& i_value) {
	if (i_value == true) data << "true";
	else data << "false";
	return *this;
}


Lace& Lace::operator<< (const string& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const char* i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<<(const float& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<<(const double& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const int8& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const int16& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const int32& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const int64& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const uint8& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const uint16& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const uint32& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const uint64& i_value) {
	data << i_value;
	return *this;
}

Lace& Lace::operator<< (const ivec2& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const ivec3& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const ivec4& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const uvec2& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const uvec3& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const uvec4& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const vec2& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const vec3& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const vec4& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<<(const quat& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	data << Result.str();
	return *this;
}

Lace& Lace::operator<<(const mat2& i_value) {
	Lace Result;
	Result << i_value[0][0] >> i_value[0][1];
	Result >> i_value[1][0] >> i_value[1][1];
	data << Result.str();
	return *this;
}

Lace& Lace::operator<<(const mat3& i_value) {
	Lace Result;
	Result << i_value[0][0] >> i_value[0][1] >> i_value[0][2];
	Result >> i_value[1][0] >> i_value[1][1] >> i_value[1][2];
	Result >> i_value[2][0] >> i_value[2][1] >> i_value[2][2];
	data << Result.str();
	return *this;
}

Lace& Lace::operator<<(const mat4& i_value) {
	Lace Result;
	Result << i_value[0][0] >> i_value[0][1] >> i_value[0][2] >> i_value[0][3];
	Result >> i_value[1][0] >> i_value[1][1] >> i_value[1][2] >> i_value[1][3];
	Result >> i_value[2][0] >> i_value[2][1] >> i_value[2][2] >> i_value[2][3];
	Result >> i_value[3][0] >> i_value[3][1] >> i_value[3][2] >> i_value[3][3];
	data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const bool& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const char* i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const float& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const double& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const int8& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const int16& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const int32& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const int64& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const uint8& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const uint16& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const uint32& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator>>(const uint64& i_value) {
	data << " " << i_value;
	return *this;
}

Lace& Lace::operator<<(const vector<string>& i_value) {
	for (string val : i_value)
		data << val << " ";
	return *this;
}

vec3 Lace::f_readVec3(const vector<string>& i_data, const uint8& i_offset) {
	vector<string> data = i_data;
	vector<vec1> transformed_data;
	if (i_offset < (data.size() + 3))
		data.erase(data.begin(), data.begin() + i_offset);
	else {
		Lace Message;
		cerr << (Message << "Failed to load" << i_data).str();
		return vec3(0.0);
	}
	for (string item : data)
		transformed_data.push_back(val(stod(item)));
	return vec3(
		transformed_data[0],
		transformed_data[1],
		transformed_data[2]
	);
}

mat4 Lace::f_readMat4(const vector<string>& i_data, const uint8& i_offset) {
	vector<string> data = i_data;
	vector<vec1> transformed_data;
	if (i_offset < (data.size() + 16))
		data.erase(data.begin(), data.begin() + i_offset);
	else {
		Lace Message;
		cerr << (Message << "Failed to load" << i_data).str();
		return mat4(1.0);
	}
	for (string item : data)
		transformed_data.push_back(val(stod(item)));
	return mat4(
		transformed_data[0], transformed_data[1], transformed_data[2], transformed_data[3],
		transformed_data[4], transformed_data[5], transformed_data[6], transformed_data[7],
		transformed_data[8], transformed_data[9], transformed_data[10], transformed_data[11],
		transformed_data[12], transformed_data[13], transformed_data[14], transformed_data[15]
	);
}