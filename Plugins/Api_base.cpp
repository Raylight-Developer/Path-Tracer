#include "Api.h"

#include <boost/config.hpp>

namespace API {

	class Base_Plugin : public API_Interface {
	public:
		void f_initialize() override {
			std::cout << "Plugin initialized\n";
		}

		void f_process() override {
			std::cout << "Plugin processing\n";
		}

		~Base_Plugin() override {
			std::cout << "Plugin cleaned up\n";
		}
	};


	extern "C" BOOST_SYMBOL_EXPORT Base_Plugin program;
	Base_Plugin program;

}