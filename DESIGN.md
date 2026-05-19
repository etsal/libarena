DESIGN
======

This document describes the rationale behind the design of libarena's imports mechanism.

(Not) importing ```vmlinux.h```
-------------------------------

Compiling libarena requires a ```vmlinux.h``` header. However, this header's contents depend
on the running system's kernel. This is a libarena-only problem, as libbpf does not
require ```vmlinux.h``` to compile.

We have 3 options on how to deal with this.

	- Option 1: No access, the libarena user provides the header.

		PROS: The user knows best and non-libarena BPF code also depends on vmlinux.h.

		CONS: Less intuitive, expects more from the user (though counterpoint: libarena
        is only part of a BPF codebase, and the user has to inlcude vmlinux.h for all
        other BPF code in the repo).

	- Option 2: Dynamically generate ```vmlinux.h``` when making libarena on the local machine.

		PROS: We use the config/kernel of the local machine. If we are building and
        deploying on the same machine, this ensures any incompatibilities between the
        code and the kernel are apparent at build time.

        CONS: In the (common) case where we're _not_ deploying on the same machine we build,
        this can cause spurious failures.

	- Option 3: Checked in a vmlinux.h copy at import time.
		PROS: Easy for the user. libarena is tied to the kernel version anyway so it is
        reasonable to hardcode a ```vmlinux.h``` for a given version of the library. This
        options also takes the burden of getting a vmlinux.h away from the user.

        CONS: If the user _does_ want to specify the ```vmlinux.h```, this may cause conflicts.
        The importer must also be careful to generate the header from a kernel with a sane
        config. If they don't, the header's data definitions may differ from that of the kernel
        of the machine being deployed.

We're going with Option 1 on this. It's more effort to provide a valid vmlinux.h, but the user
already needs to do that for non-libarena code. It's also easy to diagnose and fix a missing import.
Dealing with an incompatible ```vmlinux.h``` is less obvious.

Importing misc headers from ```selftests/bpf```
-----------------------------------------------

We choose to also import the BPF headers from the kernel's BPF ```selftests/``` subdirectory. These
headers are not necessary for libarena and do not relate to arenas in general. Nevertheless, we
include them in the repo.

The rationale is that there is no existing distribution mechanism for these headers. As of the time
writing, projects that use these headers do so by manually copying them over from the kernel tree.
The copied headers eventually get stale or, even worse, diverge from the kernel versions and become
impossible to reconcile. This issue is partly caused by the need to manually import those headers.

We have the non-libarena ```selftest/``` headers piggyback on libarena's import mechanism as a way
to distribute them. We clearly delineate between libarena and non-libarena mechanisms by putting them
in a separate directory outside of ```src/``` (```include/```). Projects using libarena get an up-to-date
version of the ```selftest/``` headers for free.

(Not) Importing ```libbpf``` headers
------------------------------------

In contrast with ```selftest/``` headers, we do _not_ import the BPF headers in ```tools/lib/bpf/```.
There are two reasons. First, the headers are already easily available becasue they are installed
in the system's standard include paths together with ```libbpf```. The motivation to re-import them
then is much weaker. Second, the newer libbpf headers are not necessarily compatible with older ```libbpf```
versions. Since the headers are tied to a specific ```libbpf``` version, we cannot import them separately.
The project can directly import the desired ```libbpf``` version or use the one installed in the system.
