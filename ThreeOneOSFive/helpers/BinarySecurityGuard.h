#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif

/// Applies PT_DENY_ATTACH via ptrace syscall to prevent debuggers from attaching
void apply_anti_debug_ptrace(void);

/// Checks if a debugger is actively tracing the process via sysctl
BOOL is_debugger_attached(void);

/// Checks for suspicious injected dynamic libraries (Frida, Flexdecrypt, dumpdecrypted, Substrate, etc.)
BOOL is_suspicious_environment(void);

/// Enforces instant process termination if tampering or dumping is detected
void enforce_binary_security(void);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
