/* SPDX-License-Identifier: GPL-2.0-only
 * bootstrap.c — modified for com.Bayan.emoji.app
 * Reads ksud from /data/user_de/0/com.Bayan.emoji.app/ksud
 */
#include <dirent.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

#define BLKROSET    0x125d
#define PKG_NAME    "com.Bayan.emoji.app"
#define KSUD_STAGE  "/data/user_de/0/" PKG_NAME "/ksud"
#define KSUD        "/data/adb/ksud"
#define MODULES_DIR "/data/adb/modules"

static int adopt_zygote_env(void) {
    FILE *f = popen("pidof zygote64 zygote", "r");
    if (!f) return -1;
    int pid = 0;
    fscanf(f, "%d", &pid);
    pclose(f);
    if (!pid) return -1;
    char path[64];
    snprintf(path, sizeof(path), "/proc/%d/environ", pid);
    int fd = open(path, O_RDONLY);
    if (fd < 0) return -1;
    char buf[4096];
    int n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    if (n <= 0) return -1;
    buf[n] = '\0';
    char *p = buf;
    while (p < buf + n) {
        char *eq = strchr(p, '=');
        if (!eq) break;
        *eq = '\0';
        setenv(p, eq + 1, 1);
        p = eq + 1 + strlen(eq + 1) + 1;
    }
    return 0;
}

static void install_ksud(void) {
    if (access(KSUD, X_OK) == 0) return;
    if (access(KSUD_STAGE, R_OK) != 0) {
        fprintf(stderr, "bootstrap: ksud not found at %s\n", KSUD_STAGE);
        return;
    }
    int src = open(KSUD_STAGE, O_RDONLY);
    if (src < 0) return;
    mkdir("/data/adb", 0700);
    int dst = open(KSUD, O_WRONLY | O_CREAT | O_TRUNC, 0755);
    if (dst < 0) { close(src); return; }
    char buf[8192];
    ssize_t nr;
    while ((nr = read(src, buf, sizeof(buf))) > 0) write(dst, buf, nr);
    close(src);
    close(dst);
    chmod(KSUD, 0755);
}

static void run_ksud(int soft_reboot, int disable_modules) {
    if (access(KSUD, X_OK) != 0) return;
    if (disable_modules) {
        DIR *d = opendir(MODULES_DIR);
        if (d) {
            struct dirent *e;
            while ((e = readdir(d)) != NULL) {
                if (e->d_name[0] == '.') continue;
                char path[512];
                snprintf(path, sizeof(path), "%s/%s/disable", MODULES_DIR, e->d_name);
                int fd = open(path, O_CREAT | O_WRONLY, 0644);
                if (fd >= 0) close(fd);
            }
            closedir(d);
        }
    }
    adopt_zygote_env();
    pid_t pid = fork();
    if (pid == 0) {
        char *args[] = { (char *)KSUD, (char *)"services", NULL };
        execv(KSUD, args);
        _exit(127);
    }
    if (soft_reboot && pid > 0) {
        sleep(2);
        pid_t rp = fork();
        if (rp == 0) {
            char *args[] = { (char *)KSUD, (char *)"soft-reboot", NULL };
            execv(KSUD, args);
            _exit(127);
        }
    }
}

int main(void) {
    install_ksud();
    int soft_reboot = 0, disable_modules = 0;
    char flags_path[256];
    snprintf(flags_path, sizeof(flags_path),
             "/data/user_de/0/%s/bootstrap_flags.txt", PKG_NAME);
    FILE *f = fopen(flags_path, "r");
    if (f) {
        fscanf(f, "soft_reboot=%d disable_modules=%d", &soft_reboot, &disable_modules);
        fclose(f);
    }
    run_ksud(soft_reboot, disable_modules);
    return 0;
}
