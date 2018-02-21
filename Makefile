har: harmain.d archive/har.d
	dmd -of=har -g -debug harmain.d archive/har.d

run_tests:
	dmd -cov archive/har.d -run test/hartests.d
