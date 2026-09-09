## A local TCP pool demonstration, not a general application platform.
platform ""
	requires {
		main! : U16 => Bool
	}
	exposes [Tcp]
	packages {}
	provides { "roc_main": main_for_host! }
	hosted {
		"pool_create": Host.create!,
		"pool_acquire": Host.acquire!,
		"pool_finish": Host.finish!,
		"pool_read": Host.read!,
		"pool_write": Host.write!,
		"pool_close": Host.close!,
	}
	targets: {
		inputs_dir: "targets/",
		arm64mac: { inputs: ["libhost.a", app] },
		x64mac: { inputs: ["libhost.a", app] },
		x64glibc: { inputs: ["Scrt1.o", "crti.o", "libhost.a", app, "crtn.o", "libc.so"] },
		arm64glibc: { inputs: ["Scrt1.o", "crti.o", "libhost.a", app, "crtn.o", "libc.so"] },
	}

import Host
import Tcp

main_for_host! : U16 => Bool
main_for_host! = main!
