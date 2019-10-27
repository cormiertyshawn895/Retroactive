insert_dylib
============

Command line utility for inserting a dylib load command into a Mach-O binary.

Does the following (to each arch if the binary is fat):

- Adds a `LC_LOAD_DYLIB` load command to the end of the load commands
- Increments the mach header's `ncmds` and adjusts its `sizeofcmds`
- ([Removes code signature if present](#removing-code-signature))

Usage
-----

```
Usage: insert_dylib dylib_path binary_path [new_binary_path]
Option flags: --inplace --weak --overwrite --strip-codesig --no-strip-codesig --all-yes
```

`insert_dylib` inserts a load command to load the `dylib_path` in `binary_path`.

Unless `--inplace` option is specified, `insert_dylib` will produce a new binary at `new_binary_path`.  
If neither `--inplace` nor `new_binary_path` is specified, the output binary will be located at the same location as the input binary with `_patched` prepended to the name.

If the `--weak` option is specified, `insert_dylib` will insert a `LC_LOAD_WEAK_DYLIB` load command instead of `LC_LOAD_DYLIB`.

### Example

```
$ cat > test.c
int main(void) {
	printf("Testing\n");
	return 0;}
^D
$ clang test.c -o test &> /dev/null
$ insert_dylib /usr/lib/libfoo.dylib test
The provided dylib path doesn't exist. Continue anyway? [y/n] y
Added LC_LOAD_DYLIB to test_patched
$ ./test
Testing
$ ./test_patched
dyld: Library not loaded: /usr/lib/libfoo.dylib
  Referenced from: /Users/Tyilo/./test_patched
  Reason: image not found
Trace/BPT trap: 5
```

#### `otool` `diff` between original and patched binary
```
$ diff -u <(otool -hl test) <(otool -hl test_patched)
--- /dev/fd/63	2014-07-30 04:08:40.000000000 +0200
+++ /dev/fd/62	2014-07-30 04:08:40.000000000 +0200
@@ -1,7 +1,7 @@
-test:
+test_patched:
 Mach header
       magic cputype cpusubtype  caps    filetype ncmds sizeofcmds      flags
- 0xfeedfacf 16777223          3  0x80          2    16       1296 0x00200085
+ 0xfeedfacf 16777223          3  0x80          2    17       1344 0x00200085
 Load command 0
       cmd LC_SEGMENT_64
   cmdsize 72
@@ -231,3 +231,10 @@
   cmdsize 16
   dataoff 8296
  datasize 64
+Load command 16
+          cmd LC_LOAD_DYLIB
+      cmdsize 48
+         name /usr/lib/libfoo.dylib (offset 24)
+   time stamp 0 Thu Jan  1 01:00:00 1970
+      current version 0.0.0
+compatibility version 0.0.0
```

#### `--weak` option

```
$ insert_dylib --weak /usr/lib/libfoo.dylib test test_patched2
The provided dylib path doesn't exist. Continue anyway? [y/n] y
Added LC_LOAD_WEAK_DYLIB to test_patched2
$ ./test_patched2
Testing
```

Removing code signature
----

To remove the code signature it is enough to delete the `LC_CODE_SIGNATURE` load command and fixup the mach header's `ncmds` and `sizeofcmds`, assuming it is the last load command.

However if you just do this `codesign_allocate` (used by `codesign` and `ldid`) will fail with the error:

```
.../codesign_allocate: file not in an order that can be processed (link edit information does not fill the __LINKEDIT segment):
```

To fix this `insert_dylib` assumes that the code signature that `LC_CODE_SIGNATURE` is in the end of the `__LINKEDIT` segment and the that the segment is in the end of the architectures slice.

It then truncate that slice to remove the code signature part of the `__LINKEDIT` segment. It also updates the `LC_SEGMENT` (or `LC_SEGMENT64`) load command for the `__LINKEDIT` segment from the new file size. If the binary is fat we also update the size and we might also move the slice and so the offset should also be updated.

After removing the code signature from the `__LINKEDIT` segment, the last thing in that segment is typically the string table. As the code signature seems to be aligned by `0x10`, and so after removing the code signature, nothing points to the padding at the end of the segment, which `codesign_allocate` doesn't like either. To fix this we just increase the size of the string table in the `LC_SYMTAB` command so it also includes the padding.

Todo
----

- Improved checking for free space to insert the new load command
- Allow removal of `LC_CODE_SIGNATURE` if it isn't the last load command
- Remove `__RESTRICT,__restrict` if not enough space (suggesion by dirkg)