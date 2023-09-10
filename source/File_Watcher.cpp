#include "File_Watcher.h"

void WatchDirectory(const wstring& directory, function<void(const wstring&)> callback) {
	HANDLE hDir = CreateFileW(
		directory.c_str(),
		FILE_LIST_DIRECTORY,
		FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
		NULL,
		OPEN_EXISTING,
		FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED,
		NULL
	);

	if (hDir == INVALID_HANDLE_VALUE) {
		cerr << "Failed to open directory for monitoring." << endl;
		return;
	}

	char buffer[4096];
	DWORD bytesReturned;
	OVERLAPPED overlapped = { 0 };

	while (true) {
		if (ReadDirectoryChangesW(
			hDir,
			buffer,
			sizeof(buffer),
			FALSE,
			FILE_NOTIFY_CHANGE_LAST_WRITE,
			&bytesReturned,
			&overlapped,
			NULL
		)) {
			if (GetOverlappedResult(hDir, &overlapped, &bytesReturned, TRUE)) {
				FILE_NOTIFY_INFORMATION* fileInfo = (FILE_NOTIFY_INFORMATION*)buffer;
				while (fileInfo) {
					if (fileInfo->Action == FILE_ACTION_MODIFIED) {
						// Construct the full file path
						wstring filePath = directory + L"\\" + fileInfo->FileName;
						callback(filePath);
					}
					fileInfo = (FILE_NOTIFY_INFORMATION*)((char*)fileInfo + fileInfo->NextEntryOffset);
				}
			}
		}

		Sleep(2500); // Sleep to avoid high CPU usage
	}

	CloseHandle(hDir);
}