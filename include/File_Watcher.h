#pragma once

#include "Include.h"

void WatchDirectory(const wstring& directory, function<void(const wstring&)> callback);