#include "Rendering/Opengl/Texture.h"

#include <Imath/ImathBox.h>
#include <OpenEXR/ImfArray.h>
#include <OpenEXR/ImfRgbaFile.h>
#include <OpenEXR/ImfNamespace.h>

void Texture::f_init(const string& i_image_path, const File_Extension::Enum& i_type) {
	if (i_type == File_Extension::EXR) {
		try {
			Imf::Array2D<Imf::Rgba> pixels;
			Imf::RgbaInputFile file(i_image_path.c_str());
			Imath::Box2i dw = file.dataWindow();

			int width = dw.max.x - dw.min.x + 1;
			int height = dw.max.y - dw.min.y + 1;
			pixels.resizeErase(height, width);

			file.setFrameBuffer(&pixels[0][0] - dw.min.x - dw.min.y * width, 1, width);
			file.readPixels(dw.min.y, dw.max.y);

			glGenTextures(1, &ID);
			glBindTexture(GL_TEXTURE_2D, ID);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, pixels.width(), pixels.height(), 0, GL_RGBA, GL_FLOAT, &pixels[0][0]);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

			glBindTexture(GL_TEXTURE_2D, 0);
		}
		catch (const Iex::BaseExc& e) {
			cerr << "OpenEXR Exception: " << e.what() << endl;
		}
	}
	else {
		cout << "ERROR: Image ( " << i_image_path << " ) Cannot be loaded.";
	}
}

void Texture::f_bind(const GLenum& i_texture_id) {
	//glActiveTexture(i_texture_id);
	glBindTexture(GL_TEXTURE_2D, ID);
}

void Texture::f_unbind() {
	glBindTexture(GL_TEXTURE_2D, 0);
}

void Texture::f_delete() {
	glDeleteTextures(1, &ID);
}