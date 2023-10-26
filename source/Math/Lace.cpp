#include "Math/Lace.h"

#include "Math/Math.h"

Lace::Lace() {
	string_data = stringstream();
	current_tab = 0;
}

Lace& Lace::setTab(const int& P_Tab) {
	current_tab = P_Tab;
	return *this;
}

Lace& Lace::nlTab(const int& P_Tab) {
	int Local_Tab = current_tab + P_Tab;
	string_data << "\n";
	while (Local_Tab--) {
		string_data << "\t";
	}
	return *this;
}

Lace& Lace::nl(const int& P_lines) {
	int Local_lines = P_lines;
	while (Local_lines--) {
		string_data << "\n";
	}
	return *this;
}

Lace& Lace::operator<< (const stringstream& i_value) {
	string_data << i_value.str();
	return *this;
}

Lace& Lace::operator<< (const bool& i_value) {
	if (i_value == true) string_data << "true";
	else string_data << "false";
	return *this;
}

Lace& Lace::operator<< (const float& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const double& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const string& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const char* i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const int& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const uint32_t& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const long int& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const long long int& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const long double& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const unsigned long long int& i_value) {
	string_data << i_value;
	return *this;
}

Lace& Lace::operator<< (const dvec2& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const dvec3& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const dvec4& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const ivec2& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const ivec3& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const ivec4& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const uvec2& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const uvec3& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator<< (const uvec4& i_value) {
	Lace Result;
	Result << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const stringstream& i_value) {
	string_data << " " << i_value.str();
	return *this;
}

Lace& Lace::operator>> (const bool& i_value) {
	if (i_value == true) string_data << " true";
	else string_data << " false";
	return *this;
}

Lace& Lace::operator>> (const float& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const double& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const string& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const char* i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const int& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const uint32_t& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const long int& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const long long int& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const long double& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const unsigned long long int& i_value) {
	string_data << " " << i_value;
	return *this;
}

Lace& Lace::operator>> (const dvec2& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const dvec3& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y >> i_value.z;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const dvec4& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const ivec2& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const ivec3& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y >> i_value.z;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const ivec4& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const uvec2& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const uvec3& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y >> i_value.z;
	string_data << Result.str();
	return *this;
}

Lace& Lace::operator>> (const uvec4& i_value) {
	Lace Result;
	Result << " " << i_value.x >> i_value.y >> i_value.z >> i_value.w;
	string_data << Result.str();
	return *this;
}

string Lace::str() const {
	return string_data.str();
}

const char* Lace::cstr() const {
	return string_data.str().c_str();
}