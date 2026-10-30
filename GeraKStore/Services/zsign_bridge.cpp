#include "zsign_bridge.h"
#include <vector>
#include <string>
#include <cstring>
#include <cstdlib>
#include <iostream>
#include <sstream>
#include <unistd.h>

// В оригинальном zhlynn/zsign сигнатура: int main(int argc, char *argv[])
// При компиляции с флагом -Dmain=zsign_main она становится:
int zsign_main(int argc, char *argv[]);

extern "C" int run_zsign_direct(
    const char* ipa_path,
    const char* p12_path,
    const char* password,
    const char* provision_path,
    const char* output_path,
    const char* bundle_id,
    const char* display_name,
    const char* temp_dir,
    char* error_log,
    int max_log_len
) {
    if (temp_dir && strlen(temp_dir) > 0) {
        setenv("TMPDIR", temp_dir, 1);
    }

    std::vector<std::string> args;
    args.push_back("zsign");

    if (p12_path && strlen(p12_path) > 0) {
        args.push_back("-k");
        args.push_back(p12_path);
    }
    if (password && strlen(password) > 0) {
        args.push_back("-p");
        args.push_back(password);
    }
    if (provision_path && strlen(provision_path) > 0) {
        args.push_back("-m");
        args.push_back(provision_path);
    }
    if (bundle_id && strlen(bundle_id) > 0) {
        args.push_back("-b");
        args.push_back(bundle_id);
    }
    if (display_name && strlen(display_name) > 0) {
        args.push_back("-n");
        args.push_back(display_name);
    }
    if (output_path && strlen(output_path) > 0) {
        args.push_back("-o");
        args.push_back(output_path);
    }
    if (ipa_path && strlen(ipa_path) > 0) {
        args.push_back("-z");
        args.push_back("9");
        args.push_back(ipa_path);
    }

    std::vector<char*> argv;
    for (size_t i = 0; i < args.size(); ++i) {
        argv.push_back(const_cast<char*>(args[i].c_str()));
    }
    argv.push_back(nullptr);

    std::stringstream buffer;
    std::streambuf* old_cerr = std::cerr.rdbuf(buffer.rdbuf());
    std::streambuf* old_cout = std::cout.rdbuf(buffer.rdbuf());

    // Сброс индекса getopt_long для повторных вызовов внутри процесса iOS
    optind = 1;

    int result = -1;
    try {
        result = zsign_main(static_cast<int>(argv.size() - 1), argv.data());
    } catch (const std::exception& e) {
        buffer << "C++ Exception: " << e.what() << "\n";
        result = -2;
    } catch (...) {
        buffer << "Unknown C++ Exception in zsign_main\n";
        result = -3;
    }

    std::cerr.rdbuf(old_cerr);
    std::cout.rdbuf(old_cout);

    if (error_log && max_log_len > 0) {
        std::string out = buffer.str();
        std::strncpy(error_log, out.c_str(), static_cast<size_t>(max_log_len - 1));
        error_log[max_log_len - 1] = '\0';
    }

    return result;
}