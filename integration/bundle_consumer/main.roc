## Downstream package template used by scripts/test-bundle.roc.
##
## The script replaces the package URL placeholder in a temporary copy. This
## file is not intended to be checked directly.
package
	[Consumer]
	{
		redis: "__ROC_REDIS_BUNDLE_URL__",
		roc: "nightly-2026-09-07-14d9829",
	}
