#pragma once

#include "Include.h"

#include "Math/Ops.h"
#include "Math/Lace.h"

#include <boost/dll/config.hpp>

class BOOST_SYMBOL_VISIBLE API_Interface {
public:
	virtual void f_initialize() = 0;
	virtual void f_process() = 0;

	virtual ~API_Interface() {};
};