#include "I-O/File.h"

#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

File::File() {
	render_camera = Camera();
}

Image::Image() {
}

bool Image::f_load(const string& i_file_path, const File_Extension::Enum& i_type) {
	if (i_type == File_Extension::PNG) {
		int t_width, t_height, t_nrChannels;
		data = stbi_load(i_file_path.c_str(), &t_width, &t_height, &t_nrChannels, 0);
		if (data) {
			if (t_nrChannels == 1)
				channel_fromat = GL_RED;
			else if (t_nrChannels == 3)
				channel_fromat = GL_RGB;
			else if (t_nrChannels == 4)
				channel_fromat = GL_RGBA;
			width = t_width;
			height = t_height;
			data_type = GL_UNSIGNED_BYTE;
			return true;
		}
		return false;
	}
}