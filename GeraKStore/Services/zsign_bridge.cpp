#include "zsign_bridge.h"
#include <vector>
#include <string>
#include <iostream>

// Объявление оригинальной функции zsign main/entrypoint
extern int zsign_main(int argc, char* argv[]);

int run_zsign_direct(
    const char* ipa_path,
    const char* p12_path,
    const char* password,
    const char* provision_path,
    const char* output_path,
    const char* bundle_id,
    const char* display_name
) {
    std::vector<std::string> args = {"zsign"};

    if (p12_path && p12_path[0] != '\0') {
        args.push_back("-k");
        args.push_back(p12_path);
    }

    if (password && password[0] != '\0') {
        args.push_back("-p");
        args.push_back(password);
    }

    if (provision_path && provision_path[0] != '\0') {
        args.push_back("-m");
        args.push_back(provision_path);
    }

    if (output_path && output_path[0] != '\0') {
        args.push_back("-o");
        args.push_back(output_path);
    }

    if (bundle_id && bundle_id[0] != '\0') {
        args.push_back("-b");
        args.push_back(bundle_id);
    }

    if (display_name && display_name[0] != '\0') {
        args.push_back("-n");
        args.push_back(display_name);
    }

    if (ipa_path && ipa_path[0] != '\0') {
        args.push_back(ipa_path);
    }

    std::vector<char*> c_args;
    for (auto& s : args) {
        c_args.push_back(const_cast<char*>(s.c_str()));
    }
    c_args.push_back(nullptr);

    try {
        return zsign_main(static_cast<int>(c_args.size() - 1), c_args.data());
    } catch (...) {
        return -1;
    }
}
