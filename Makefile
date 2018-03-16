# Note: recommended way is via `dub build`
out_D=./out/

all: har run_tests

har: harmain.d src/archive/har.d
	dmd -of=${out_D}/har -g -debug harmain.d src/archive/har.d

run_tests:
	dmd -cov src/archive/har.d -run test/hartests.d
	rdmd test_command_line_tool.d
