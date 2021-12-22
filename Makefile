PRE_JS = build/pre.js
POST_JS_SYNC = build/post-sync.js
POST_JS_WORKER = build/post-worker.js

COMMON_BSFS = vp9_superframe
COMMON_FILTERS = aresample scale crop overlay hstack vstack
COMMON_DEMUXERS = matroska ogg mov mp3 wav image2 concat
COMMON_DECODERS = hevc vp8 vp9 h264 vorbis opus mp3 aac pcm_s16le pcm_s24le pcm_s32le pcm_s64le flac jpeg png webp

WEBM_MUXERS = webm ogg null
WEBM_ENCODERS = libvpx_vp9 libopus vorbis
FFMPEG_WEBM_BC = build/ffmpeg-webm/ffmpeg.bc
FFMPEG_WEBM_PC_PATH = ../opus/dist/lib/pkgconfig
WEBM_SHARED_DEPS = \
	build/opus/dist/lib/libopus.so \
	build/libvpx/dist/lib/libvpx.so

all: ffmpeg.js

clean: clean-js \
	clean-opus clean-libvpx clean-ffmpeg-webm
clean-js:
	rm -f ffmpeg*.js
clean-opus:
	cd build/opus && git clean -xdf
clean-libvpx:
	cd build/libvpx && git clean -xdf
clean-ffmpeg-webm:
	cd build/ffmpeg-webm && git clean -xdf

build/opus/configure:
	cd build/opus && ./autogen.sh

build/opus/dist/lib/libopus.so: build/opus/configure
	cd build/opus && \
	emconfigure ./configure \
		CFLAGS=-O3 \
		--prefix="$$(pwd)/dist" \
		--disable-static \
		--disable-doc \
		--disable-extra-programs \
		--disable-asm \
		--disable-rtcd \
		--disable-intrinsics \
		--disable-hardening \
		--disable-stack-protector \
		&& \
	emmake make -j && \
	emmake make install

build/libvpx/dist/lib/libvpx.so:
	cd build/libvpx && \
	git reset --hard && \
	patch -p1 < ../libvpx-fix-ld.patch && \
	emconfigure ./configure \
		--prefix="$$(pwd)/dist" \
		--target=generic-gnu \
		--disable-dependency-tracking \
		--disable-multithread \
		--disable-runtime-cpu-detect \
		--enable-shared \
		--disable-static \
		\
		--disable-examples \
		--disable-docs \
		--disable-unit-tests \
		--disable-webm-io \
		--disable-libyuv \
		--disable-vp8 \
		--disable-vp9-decoder \
		&& \
	emmake make -j && \
	emmake make install

FFMPEG_COMMON_ARGS = \
	--cc=emcc \
	--ranlib=emranlib \
	--enable-cross-compile \
	--target-os=none \
	--arch=x86 \
	--disable-runtime-cpudetect \
	--disable-asm \
	--disable-fast-unaligned \
	--disable-pthreads \
	--disable-w32threads \
	--disable-os2threads \
	--disable-debug \
	--disable-stripping \
	--disable-safe-bitstream-reader \
	\
	--disable-all \
	--enable-ffmpeg \
	--enable-avcodec \
	--enable-avformat \
	--enable-avfilter \
	--enable-swresample \
	--enable-swscale \
	--disable-network \
	--disable-d3d11va \
	--disable-dxva2 \
	--disable-vaapi \
	--disable-vdpau \
	$(addprefix --enable-bsf=,$(COMMON_BSFS)) \
	$(addprefix --enable-decoder=,$(COMMON_DECODERS)) \
	$(addprefix --enable-demuxer=,$(COMMON_DEMUXERS)) \
	--enable-protocol=file \
	$(addprefix --enable-filter=,$(COMMON_FILTERS)) \
	--disable-bzlib \
	--disable-iconv \
	--disable-libxcb \
	--disable-lzma \
	--disable-sdl2 \
	--disable-securetransport \
	--disable-xlib \
	--enable-zlib

build/ffmpeg-webm/ffmpeg.bc: $(WEBM_SHARED_DEPS)
	cd build/ffmpeg-webm && \
	EM_PKG_CONFIG_PATH=$(FFMPEG_WEBM_PC_PATH) emconfigure ./configure \
		$(FFMPEG_COMMON_ARGS) \
		$(addprefix --enable-encoder=,$(WEBM_ENCODERS)) \
		$(addprefix --enable-muxer=,$(WEBM_MUXERS)) \
		--enable-gpl \
		--enable-libopus \
		--enable-libvpx \
		--extra-cflags="-s USE_ZLIB=1 -I../libvpx/dist/include" \
		--extra-ldflags="-r -L../libvpx/dist/lib" \
		&& \
	emmake make -j EXESUF=.bc

EMCC_COMMON_ARGS = \
	-Oz \
	--closure 1 \
	--memory-init-file 0 \
	-s WASM=0 \
	-s WASM_ASYNC_COMPILATION=0 \
	-s ASSERTIONS=0 \
	-s EXIT_RUNTIME=1 \
	-s NODEJS_CATCH_EXIT=0 \
	-s NODEJS_CATCH_REJECTION=0 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-lnodefs.js -lworkerfs.js \
	--pre-js $(PRE_JS) \
	-o $@

# ffmpeg-webm.js: $(FFMPEG_WEBM_BC) $(PRE_JS) $(POST_JS_SYNC)
# 	emcc $(FFMPEG_WEBM_BC) $(WEBM_SHARED_DEPS) \
# 		--post-js $(POST_JS_SYNC) \
# 		$(EMCC_COMMON_ARGS)

ffmpeg.js: $(FFMPEG_WEBM_BC) $(PRE_JS) $(POST_JS_WORKER)
	emcc $(FFMPEG_WEBM_BC) $(WEBM_SHARED_DEPS) \
		--post-js $(POST_JS_WORKER) \
		$(EMCC_COMMON_ARGS)
