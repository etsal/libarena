This repository
===============

This is the repository for `libarena`, a BPF runtime built on top of the BPF arena
map abstraction. `libarena` provides an allocator, data structures, and common BPF
programming abstractions. The code for `libarena` simplifies the BPF coding experience
by providing a reusable and centrally managed/updated library.

We sync `libarena` almost identically to [libbpf](https://github.com/libbpf/libbpf).
The authoritative library source code is on the [bpf-next Linux source tree]
(https://git.kernel.org/pub/scm/linux/kernel/git/bpf/bpf-next.git/). The location of the
code in the tree is `tools/testing/selftests/bpf/libarena`.

The present repo's purpose is solely to make it easier to include and update libarena
in BPF codebases as a git submodule. Please send feature requests and bugfixes on the
[BPF mailing list](https://lore.kernel.org/bpf). *Issues and PRs on this repo will be
ignored and eventually closed.*

What follows is instructions on how to use the sync script to update this repo
with the most recent libarena version from the kernel repo.

Setup expectations
------------------

Most of the mundane mechanical tasks like bpf and bpf-next tree merge, Git
history transformation, cherry-picking relevant commits, re-generating
auto-generated headers, etc. are taken care of by the
[sync-kernel.sh script](https://github.com/libarena/libarena/blob/master/scripts/sync-kernel.sh).
We do occasionally need to manually unblock parts of the process (see below).

The sync script expects a local copy of the upstream Linux repo whose HEAD
points to bpf-next's master branch. The local copy must also have a 
separate local branch pointing to the bpf tree's master branch. The 'sync-kernel.sh'
script automatically merges the branches and syncs the result into libarena.

Below, we assume that Linux repo is located at `~/linux`, its current head is
at latest `bpf-next/master`, and libarena's Github repo is located at
`~/libarena`, checked out to latest commit on `master` branch. In the example
we'll be running `sync-kernel.sh` from inside `~/libarena`, but the current
directory doesn't matter.

Running the setup script
------------------------

The first step always to run the `sync-kernel.sh` script. It expects three arguments:

```
$ scripts/sync-kernel.sh <libarena-repo> <kernel-repo> <bpf-branch>
```

We will store the script's entire output in `/tmp/libarena-sync.txt` and
put it into PR summary later on. **Please always include the output in
the PR summary for others to cross-reference.**

```
$ scripts/sync-kernel.sh ~/libarena ~/linux bpf-master | tee /tmp/libarena-sync.txt
Dumping existing libarena commit signatures...
WORKDIR:          /home/etsal/libarena
LINUX REPO:       /home/etsal/linux
libarena REPO:      /home/etsal/libarena
...
```

Most of the time the command outright succeeds. If it does not, there is probably
a conflict between the bpf and bpf-next branches. This in turn should only happen
when the bpf branch includes a fix that conflicts with new features in bpf-next.

In case of a conflict the script will list a diff describing the conflict. If it
looks sensible and expected, type `y` and script will proceed.

Example diff below:

```
Verifying Linux's and Github's libarena state
Switched to a new branch 'libarena-view-2026-05-19T16-28-16.954Z'
Rewrite e651f3ce1364d06d97bb7cc4aa5b23146420a67d (4/4) (13 seconds passed, remaining 0 predicted)     
Ref 'refs/heads/libarena-view-2026-05-19T16-28-16.954Z' was rewritten
Rewrite 6b54a8b2a300cb2511625b448e423320f93cae79 (1/1) (0 seconds passed, remaining 0 predicted)    
Ref 'refs/heads/libarena-view-2026-05-19T16-28-16.954Z' was rewritten
Comparing list of files...
Comparing file contents...
--- /home/etsal/linux/libarena/include/bpf_atomic.h     2026-05-19 09:29:25.880135811 -0700
+++ /home/etsal/libarena/libarena/include/bpf_atomic.h  2026-05-19 09:28:44.834354589 -0700
@@ -42,9 +42,7 @@
 
 #define READ_ONCE(x) (*(volatile typeof(x) *)&(x))
 
-#ifndef WRITE_ONCE
 #define WRITE_ONCE(x, val) ((*(volatile typeof(x) *)&(x)) = (val))
-#endif
 
 #define cmpxchg(p, old, new) __sync_val_compare_and_swap((p), old, new)
 
/home/etsal/linux/libarena/include/bpf_atomic.h and /home/etsal/libarena/libarena/include/bpf_atomic.h are different!
Unfortunately, there are some inconsistencies, please double check.
```

If sync is successful, your `~/linux` repo will be left in original state on
the original HEAD commit. `~/libarena` repo will now be on a new branch, named
`libarena-sync-<timestamp>` (e.g., `libarena-view-2026-05-19T16-28-16.954Z`).
Push this branch into your fork of `libarena/libarena` Github repo and create a PR.

By default Github will turn above branch name into PR with subject "libarena sync
2026 05 19 t09 28 44.834 z". Please fix this into a proper timestamp, e.g.:
"libarena sync 2026-05-19T16:28:44.834Z". Thank you!

Once the PR is created, libarena CI will run a bunch of tests to check that
everything is good. In simple cases that would be all you'd need to do. In 
more complicated cases some extra adjustments might be necessary.

**Please, keep naming and style consistent.** If you had to modify the sync
script, prefix it with `sync: `. Also make sure that each such commit has
`Signed-off-by: Your Full Name <your@email.com>`, just like you'd do that for
Linux upstream patch. libarena closely follows kernel conventions and style,
so please help maintain that.

Including new sources
---------------------

If existing source files should be included in libarena, they must initially be
manually included into this repo. Please include the version of the file corresponding
to the most recent sync head. Subsequent syncs will properly update the file.

Troubleshooting
---------------

If something goes wrong and sync script exits early or is terminated early by
user, you might end up with a `~/linux` repo on temporary sync-related branch. 
The original bpf-next and bpf branches are never modified, so it is safe to
discard the temporary branch checkout bpf-next.

You might need to do the same for your `~/libarena` repo sometimes, depending at
which stage the sync script was terminated.
