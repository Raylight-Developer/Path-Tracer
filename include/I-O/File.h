#pragma once

#include "Math/Ops.h"
#include "Rendering/Material.h"
#include "Object/Camera.h"

struct Image {
	uint16_t width;
	uint16_t height;
	unsigned char* data;
	int channel_fromat;
	int data_type;
	
	Image();
	bool f_load(const string& i_file_path, const bool& i_flip);
};

struct File {
	Camera render_camera;
	File();
};