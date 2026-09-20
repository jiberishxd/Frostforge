// Read-only CASC inspection/extraction; never writes into the game installation.
#include "CascLib.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <vector>

static bool progress(void *, CASC_PROGRESS_MSG message, const char *object, DWORD, DWORD) {
    std::fprintf(stderr, "CASC stage %d: %s\n", message, object ? object : "");
    return false;
}

int main(int argc, char **argv) {
    if (argc < 3) { std::fprintf(stderr, "usage: casc_extract STORAGE MASK [OUTPUT]\n"); return 2; }
    HANDLE storage = nullptr;
    CASC_OPEN_STORAGE_ARGS args = {};
    args.Size = sizeof(args);
    args.dwLocaleMask = CASC_LOCALE_ENUS;
    args.PfnProgressCallback = progress;
    args.szLocalPath = argv[1];
    if (!CascOpenStorageEx(nullptr, &args, false, &storage)) {
        std::fprintf(stderr, "Cannot open storage: %u\n", GetCascError()); return 1;
    }
    if (argc == 3) {
        CASC_FIND_DATA data;
        HANDLE search = CascFindFirstFile(storage, argv[2], &data, nullptr);
        if (search != INVALID_HANDLE_VALUE) {
            do { std::puts(data.szFileName); } while (CascFindNextFile(search, &data));
            CascFindClose(search);
        }
    } else {
        HANDLE file = nullptr;
        if (!CascOpenFile(storage, argv[2], CASC_LOCALE_ENUS, CASC_OPEN_BY_NAME, &file)) {
            std::fprintf(stderr, "Cannot open asset: %u\n", GetCascError()); CascCloseStorage(storage); return 1;
        }
        ULONGLONG size = 0;
        if (!CascGetFileSize64(file, &size) || size > 64 * 1024 * 1024) return 1;
        std::vector<unsigned char> bytes((size_t)size);
        DWORD read = 0;
        if (!CascReadFile(file, bytes.data(), (DWORD)size, &read) || read != size) return 1;
        FILE *out = std::fopen(argv[3], "wb");
        if (!out) return 1;
        if (std::fwrite(bytes.data(), 1, bytes.size(), out) != bytes.size()) return 1;
        std::fclose(out);
        CascCloseFile(file);
        std::printf("Extracted %llu bytes\n", size);
    }
    CascCloseStorage(storage);
    return 0;
}
