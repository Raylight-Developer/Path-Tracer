#define HIGH_PRECISION false
#define DISPLAY_GUI false

#include "Include.h"

#include "Rendering/GLSL_Renderer.h"

#include <boost/dll/import.hpp>
#include "Api.h"

int main() {
	GLSL_Renderer renderer = GLSL_Renderer();
	vector<unique_ptr<API_Interface>> plugins;

	string directory_path = "./Plugins";

	for (const auto& entry : fs::directory_iterator(directory_path)) {
		if (fs::is_regular_file(entry.path()) && entry.path().extension() == ".dll") {
			cout << "Found DLL file: " << entry.path().filename() << std::endl;

			boost::dll::fs::path lib_path("./Plugins");                // argv[1] contains path to directory with our plugin library
			boost::shared_ptr<API_Interface> plugin;                   // variable to hold a pointer to plugin variable
			std::cout << "Loading the plugin" << std::endl;

			plugin = boost::dll::import_symbol<API_Interface>(         // type of imported symbol is located between `<` and `>`
				lib_path / entry.path().filename(),                    // path to the library and library name
				entry.path().filename().string(),                      // name of the symbol to import
				boost::dll::load_mode::append_decorations              // makes `libmy_plugin_sum.so` or `my_plugin_sum.dll` from `my_plugin_sum`
			);
		}
	}


	renderer.f_init();
	return 0;
}