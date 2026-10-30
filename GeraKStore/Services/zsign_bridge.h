#ifndef ZSIGN_BRIDGE_H
#define ZSIGN_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

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
);

#ifdef __cplusplus
}
#endif

#endif
