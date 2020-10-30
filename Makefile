current_dir := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

build: build-virtiofs build-fusedev
	cargo fmt -- --check

release: build-virtiofs-release build-fusedev-release
	cargo fmt -- --check

build-virtiofs:
	# TODO: switch to --out-dir when it moves to stable
	# For now we build with separate target directories
	cargo build --features=virtiofs --target-dir target-virtiofs
	cargo clippy --features=virtiofs --target-dir target-virtiofs -- -Dclippy::all

build-fusedev:
	cargo build --features=fusedev --target-dir target-fusedev
	cargo clippy --features=fusedev --target-dir target-fusedev -- -Dclippy::all

build-virtiofs-release:
	cargo build --features=virtiofs --release --target-dir target-virtiofs

build-fusedev-release:
	cargo build --features=fusedev --release --target-dir target-fusedev

static-release:
	cargo build --target x86_64-unknown-linux-musl --features=fusedev --release --target-dir target-fusedev
	cargo build --target x86_64-unknown-linux-musl --features=virtiofs --release --target-dir target-virtiofs

test: build
	# Run smoke test and unit tests
	RUST_BACKTRACE=1 cargo test --features=virtiofs --target-dir target-virtiofs --workspace -- --nocapture --test-threads=15 --skip integration
	RUST_BACKTRACE=1 cargo test --features=fusedev --target-dir target-fusedev --workspace -- --nocapture --test-threads=15

docker-smoke:
	docker build -t nydus-rs-smoke misc/smoke
	docker run -it --rm --privileged -v ${current_dir}:/nydus-rs -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.cargo:/usr/local/cargo -v fuse-targets:/nydus-rs/target-fusedev -v virtiofs-targets:/nydus-rs/target-virtiofs nydus-rs-smoke

docker-static:
	# For static build with musl
	docker build -t nydus-rs-static misc/musl-static
	docker run -it --rm --privileged -v ${current_dir}:/nydus-rs -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/.cargo:/root/.cargo nydus-rs-static
