#pragma once

#include "Include.h"

struct Lights {

};

struct Camera{

};

struct Scene {
	vector<Lights> lights;
	Camera render_camera;

	Scene();
};