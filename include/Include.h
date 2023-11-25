#pragma once

#include <unordered_map>
#include <unordered_set>
#include <filesystem>
#include <windows.h>
#include <stdexcept>
#include <iostream>
#include <optional>
#include <direct.h>
#include <iomanip>
#include <sstream>
#include <fstream>
#include <variant>
#include <cstdlib>
#include <cstring>
#include <numeric>
#include <cerrno>
#include <vector>
#include <chrono>
#include <thread>
#include <random>
#include <future>
#include <math.h>
#include <array>
#include <tuple>
#include <any>
#include <map>
#include <set>

#include <glad.h>
#include <GLFW/glfw3.h>

#include <glm.hpp>
#include <gtc/type_ptr.hpp>
#include <gtx/euler_angles.hpp>
#include <gtx/rotate_vector.hpp>
#include <gtc/matrix_transform.hpp>

#include <imgui.h>
#include <backends/imgui_impl_glfw.h>
#include <backends/imgui_impl_opengl3.h>

#define GL_SILENCE_DEPRECATION

using namespace std;
namespace fs = std::filesystem;

using fvec1 = float;     // 32-bits
using fvec2 = glm::vec2; // 64-bits
using fvec3 = glm::vec3; // 96-bits
using fvec4 = glm::vec4; // 128-bits
using fquat = glm::quat; // 128-bits
using fmat2 = glm::mat2; // 128-bits
using fmat3 = glm::mat3; // 288-bits
using fmat4 = glm::mat4; // 512-bits

using dvec1 = double;     // 64-bits
using dvec2 = glm::dvec2; // 128-bits
using dvec3 = glm::dvec3; // 196-bits
using dvec4 = glm::dvec4; // 256-bits
using dquat = glm::dquat; // 256-bits
using dmat2 = glm::dmat2; // 256-bits
using dmat3 = glm::dmat3; // 576-bits
using dmat4 = glm::dmat4; // 1024-bits

using uint8  = uint8_t;  //max: 255
using uint16 = uint16_t; //max: 65'535
using uint32 = uint32_t; //max: 4'294'967'295
using uint64 = uint64_t; //max: 18'446'744'073'709'551'615

using int8  = int8_t;  // min: -128 | max: 127
using int16 = int16_t; // min: -32'768 | max: 32'767
using int32 = int32_t; // min: -2'147'483'648 | max: 2'147'483'647
using int64 = int64_t; // min: -9'223'372'036'854'775'808 | max: 9'223'372'036'854'775'807

using uvec2 = glm::uvec2; // 64-bits
using uvec3 = glm::uvec3; // 96-bits
using uvec4 = glm::uvec4; // 128-bits

using ivec2 = glm::ivec2; // 64-bits
using ivec3 = glm::ivec3; // 96-bits
using ivec4 = glm::ivec4; // 128-bits

using val32 = float;  // float
using val64 = double; // double

#if HIGH_PRECISION
	using vec1 = double;     // 64-bits
	using vec2 = glm::dvec2; // 128-bits
	using vec3 = glm::dvec3; // 196-bits
	using vec4 = glm::dvec4; // 256-bits
	using quat = glm::dquat; // 256-bits
	using mat2 = glm::dmat2; // 256-bits
	using mat3 = glm::dmat3; // 576-bits
	using mat4 = glm::dmat4; // 1024-bits
	inline vec1 val(const float& val)  { return static_cast<double>(val); }
	inline vec1 val(const double& val) { return val; }

	const vec1 MAX_VEC1 = numeric_limits<double>::max();
#else
	using vec1 = float;     // 32-bits
	using vec2 = glm::vec2; // 64-bits
	using vec3 = glm::vec3; // 96-bits
	using vec4 = glm::vec4; // 128-bits
	using quat = glm::quat; // 128-bits
	using mat2 = glm::mat2; // 128-bits
	using mat3 = glm::mat3; // 288-bits
	using mat4 = glm::mat4; // 512-bits
	inline vec1 val(const float& val)  { return val; }
	inline vec1 val(const double& val) { return static_cast<float>(val); }

	const vec1 MAX_VEC1 = numeric_limits<float>::max();
#endif


inline vec1 val(const int& val)    { return static_cast<vec1>(val); }
inline vec1 val(const uint32& val) { return static_cast<vec1>(val); }
inline vec2 vec(const uvec2& val)  { return static_cast<vec2>(val); }

#define PI          vec1(3.141592653589793)
#define TWO_PI      vec1(6.283185307179586)
#define INVERTED_PI vec1(0.318309886183791)
#define DEG_RAD     vec1(0.017453292519943)
#define EULER       vec1(2.718281828459045)