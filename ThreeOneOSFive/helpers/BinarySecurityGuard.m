#import "BinarySecurityGuard.h"
#import <dlfcn.h>
#import <sys/types.h>
#import <sys/sysctl.h>
#import <unistd.h>
#import <mach-o/dyld.h>
#import <ctype.h>
#import <string.h>

#define PT_DENY_ATTACH 31
typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

static BOOL contains_ignore_case(const char* haystack, const char* needle) {
    if (!haystack || !needle) return NO;
    size_t hlen = strlen(haystack);
    size_t nlen = strlen(needle);
    if (nlen > hlen) return NO;
    
    for (size_t i = 0; i <= hlen - nlen; i++) {
        size_t j = 0;
        while (j < nlen && tolower((unsigned char)haystack[i + j]) == tolower((unsigned char)needle[j])) {
            j++;
        }
        if (j == nlen) return YES;
    }
    return NO;
}

void apply_anti_debug_ptrace(void) {
    void* handle = dlopen(NULL, RTLD_GLOBAL | RTLD_NOW);
    if (handle) {
        ptrace_ptr_t ptrace_func = (ptrace_ptr_t)dlsym(handle, "ptrace");
        if (ptrace_func) {
            ptrace_func(PT_DENY_ATTACH, 0, 0, 0);
        }
        dlclose(handle);
    }
}

BOOL is_debugger_attached(void) {
    int name[4];
    struct kinfo_proc info;
    size_t info_size = sizeof(info);
    
    memset(&info, 0, sizeof(info));
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
    
    if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
        return NO;
    }
    
    return (info.kp_proc.p_flag & P_TRACED) != 0;
}

BOOL is_suspicious_environment(void) {
    // 1. Check DYLD injection environment variables
    if (getenv("DYLD_INSERT_LIBRARIES") != NULL) {
        return YES;
    }
    if (getenv("DYLD_FRAMEWORK_PATH") != NULL) {
        return YES;
    }
    
    // 2. Scan loaded Mach-O images for known dumping & hooking frameworks
    static const char* suspicious_signatures[] = {
        "fridagadget",
        "frida",
        "bagbak",
        "flexdecrypt",
        "dumpdecrypted",
        "cynject",
        "cycript",
        "mobilesubstrate",
        "substrateloader",
        "libhooker",
        "sslkillswitch",
        "shadow.dylib",
        "liberty",
        "choicy",
        "flyjb",
        "unsub"
    };
    int sig_count = sizeof(suspicious_signatures) / sizeof(suspicious_signatures[0]);
    
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* imageName = _dyld_get_image_name(i);
        if (!imageName) continue;
        for (int j = 0; j < sig_count; j++) {
            if (contains_ignore_case(imageName, suspicious_signatures[j])) {
                return YES;
            }
        }
    }
    
    return NO;
}

void enforce_binary_security(void) {
    apply_anti_debug_ptrace();
    if (is_debugger_attached() || is_suspicious_environment()) {
        __builtin_trap();
    }
}

// Automatic early execution before main()
__attribute__((constructor(101)))
static void auto_init_binary_shield(void) {
    apply_anti_debug_ptrace();
    if (is_debugger_attached() || is_suspicious_environment()) {
        __builtin_trap();
    }
}
