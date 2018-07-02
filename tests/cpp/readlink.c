#include <assert.h>
#include <string.h>
#include <unistd.h>
#include <emscripten.h>

#define BUF_SIZE 64

void check_symlink(const char *path, const char *symlink_val) {
  char buf[BUF_SIZE] = { 0 };
  int bytes_read;

  bytes_read = readlink(path, buf, BUF_SIZE);

  assert(bytes_read == strlen(symlink_val));
  assert(strcmp(buf, symlink_val) == 0);
}

int main() {
    EM_ASM(
        window._cvmfs_testname = 'readlink';
    );

    const char symlink_path[] = "/cvmfs/emscripten.cvmfs.io/test/symlink";
    const char symlink_val[] = "/cvmfs/emscripten.cvmfs.io/test/regular";
    check_symlink(symlink_path, symlink_val);

    // $(PREFIX)/regular
    const char varlink_path[] = "/cvmfs/emscripten.cvmfs.io/test/varlink";
    check_symlink(varlink_path, "/regular");

    // $(PREFIX)/$(INFIX)/$(POSTFIX)
    const char multivar_path[] = "/cvmfs/emscripten.cvmfs.io/test/varlink-multi";
    check_symlink(multivar_path, "/");

    EM_ASM(
        CVMFS.setSymlinkVar('PREFIX', '/home');
    );
    check_symlink(varlink_path, "/home/regular");
    check_symlink(multivar_path, "/home");

    EM_ASM(
        CVMFS.setSymlinkVar('INFIX', 'emscripten');
    );
    check_symlink(multivar_path, "/home/emscripten");

    EM_ASM(
        CVMFS.setSymlinkVar('POSTFIX', 'cvmfs');
    );
    check_symlink(multivar_path, "/home/emscripten/cvmfs");

    return 0;
}