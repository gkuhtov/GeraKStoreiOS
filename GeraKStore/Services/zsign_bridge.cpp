#include "zsign_bridge.h"
#include <vector>
#include <string>
#include <sstream>
#include <iostream>
#include <cstring>

extern int zsign_main(int argc, char* argv[]);

int run_zsign_direct(
    const char* ipa_path,
    const char* p12_path,
    const char* password,
    const char* provision_path,
    const char* output_path,
    const char* bundle_id,
    const char* display_name,
    char* error_log,
    int max_log_len
) {
    std::vector<std::string> args = {"zsign"};

    if (p12_path && p12_path[0] != '\0') {
        args.push_back("-k");
        args.push_back(p12_path);
    }

    // Всегда передаем пароль (даже если он пустой "")
    args.push_back("-p");
    args.push_back(password ? password : "");

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

    // Перехватываем cout и cerr
    std::stringstream buffer;
    std::streambuf* old_cout = std::cout.rdbuf(buffer.rdbuf());
    std::streambuf* old_cerr = std::cerr.rdbuf(buffer.rdbuf());

    int result = -1;
    try {
        result = zsign_main(static_cast<int>(c_args.size() - 1), c_args.data());
    } catch (const std::exception& e) {
        buffer << "\nException: " << e.what();
        result = -1;
    } catch (...) {
        buffer << "\nUnknown C++ exception";
        result = -1;
    }

    std::cout.rdbuf(old_cout);
    std::cerr.rdbuf(old_cerr);

    if (error_log && max_log_len > 0) {
        std::string log_str = buffer.str();
        strncpy(error_log, log_str.c_str(), max_log_len - 1);
        error_log[max_log_len - 1] = '\0';
    }

    return result;
}
