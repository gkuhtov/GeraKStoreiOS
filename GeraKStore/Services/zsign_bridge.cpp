#include "zsign_bridge.h"
#include <vector>
#include <string>
#include <iostream>
#include <unistd.h>
#include <fcntl.h>
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

    if (password) {
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

    // Оптимальный уровень сжатия для ускорения на iOS
    args.push_back("-z");
    args.push_back("1");

    if (ipa_path && ipa_path[0] != '\0') {
        args.push_back(ipa_path);
    }

    std::vector<char*> c_args;
    for (auto& s : args) {
        c_args.push_back(const_cast<char*>(s.c_str()));
    }
    c_args.push_back(nullptr);

    // Создаем pipe для перехвата Си-дескрипторов stdout и stderr (printf, puts)
    int pipe_fds[2];
    if (pipe(pipe_fds) == -1) {
        return -1;
    }

    int saved_stdout = dup(STDOUT_FILENO);
    int saved_stderr = dup(STDERR_FILENO);

    dup2(pipe_fds[1], STDOUT_FILENO);
    dup2(pipe_fds[1], STDERR_FILENO);
    close(pipe_fds[1]);

    int result = -1;
    try {
        result = zsign_main(static_cast<int>(c_args.size() - 1), c_args.data());
    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        result = -1;
    } catch (...) {
        std::cerr << "Unknown exception" << std::endl;
        result = -1;
    }

    fflush(stdout);
    fflush(stderr);

    // Восстанавливаем дескрипторы
    dup2(saved_stdout, STDOUT_FILENO);
    dup2(saved_stderr, STDERR_FILENO);
    close(saved_stdout);
    close(saved_stderr);

    // Считываем всё, что zsign вывел в консоль
    if (error_log && max_log_len > 0) {
        // Делаем чтение неблокирующим
        fcntl(pipe_fds[0], F_SETFL, O_NONBLOCK);
        ssize_t bytes_read = read(pipe_fds[0], error_log, max_log_len - 1);
        if (bytes_read > 0) {
            error_log[bytes_read] = '\0';
        } else {
            error_log[0] = '\0';
        }
    }
    close(pipe_fds[0]);

    return result;
}
