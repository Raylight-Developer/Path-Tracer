#define HIGH_PRECISION false
#define DISPLAY_GUI false

#include "Include.h"
#include "Rendering/GLSL_Renderer.h"

//int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow) {
int main() {
	GLSL_Renderer renderer = GLSL_Renderer();
	renderer.f_init();
	return 0;
}