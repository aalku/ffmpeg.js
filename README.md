# [FFmpeg4JS](https://www.npmjs.com/package/ffmpeg4js)

This library provides FFmpeg builds ported to JavaScript using [Emscripten project](https://github.com/emscripten-core/emscripten). Builds are optimized for in-browser use: minimal size for faster loading, asm.js, performance tunings, etc. Though they work in Node as well.

## Builds

### Decoders

> hevc vp8 vp9 h264  
> jpeg png webp  
> vorbis opus mp3 aac flac  
> pcm_s16le pcm_s24le pcm_s32le pcm_s64le  

### Encoders

> libvpx_vp9 libopus vorbis

## Version scheme

FFmpeg4JS uses the following version pattern: `major.minor.9ddd`, where:
* **major** - FFmpeg's major version number used in the builds.
* **minor** - FFmpeg's minor version.
* **ddd** - FFmpeg4JS own patch version. Should not be confused with FFmpeg's patch version number.

Example: `4.4.1004`

## Usage

See documentation on [Module object](https://emscripten.org/docs/api_reference/module.html#affecting-execution) for the list of options that you can pass.

### Sync run

FFmpeg4JS provides common module API, `ffmpeg-webm.js` is the default module.

```js
const ffmpeg = require("ffmpeg4js");
let stdout = "";
let stderr = "";
// Print FFmpeg's version.
ffmpeg({
  arguments: ["-version"],
  print: function(data) { stdout += data + "\n"; },
  printErr: function(data) { stderr += data + "\n"; },
  onExit: function(code) {
    console.log("Process exited with code " + code);
    console.log(stdout);
    console.log(stderr);
  },
});
```

### Files

Empscripten supports several types of [file systems](https://emscripten.org/docs/api_reference/Filesystem-API.html#file-systems).  
FFmpeg4JS uses [MEMFS](https://emscripten.org/docs/api_reference/Filesystem-API.html#memfs) to store the input/output files in FFmpeg's working directory.  
You need to pass *Array* of *Object* to `MEMFS` option with the following keys:
* **name** *(String)* - File name, can't contain slashes.
* **data** *(ArrayBuffer/ArrayBufferView/Array)* - File data.

FFmpeg4JS resulting object has `MEMFS` option with the same structure and contains files which weren't passed to the input, i.e. new files created by FFmpeg.

```js
const ffmpeg = require("ffmpeg4js");
const fs = require("fs");
const testData = new Uint8Array(fs.readFileSync("test.webm"));
// Encode test video to VP8.
const result = ffmpeg({
  MEMFS: [{name: "test.webm", data: testData}],
  arguments: ["-i", "test.webm", "-c:v", "libvpx", "-an", "out.webm"],
});
// Write out.webm to disk.
const out = result.MEMFS[0];
fs.writeFileSync(out.name, Buffer(out.data));
```

You can also mount other FS by passing *Array* of *Object* to `mounts` option with the following keys:
* **type** *(String)* - Name of the file system.
* **opts** *(Object)* - Underlying file system options.
* **mountpoint** *(String)* - Mount path, must start with a slash, must not contain other slashes and also the following paths are blacklisted: `/tmp`, `/home`, `/dev`, `/work`. Mount directory will be created automatically before mount.

See documentation of [FS.mount](https://emscripten.org/docs/api_reference/Filesystem-API.html#FS.mount) for more details.

```js
const ffmpeg = require("ffmpeg4js");
ffmpeg({
  // Mount /data inside application to the current directory.
  mounts: [{type: "NODEFS", opts: {root: "."}, mountpoint: "/data"}],
  arguments: ["-i", "/data/test.webm", "-c:v", "libvpx", "-an", "-y", "/data/out.webm"],
});
// out.webm was written to the current directory.
```

## Build

Ubuntu example:

```bash
sudo apt-get update
sudo apt-get install -y git python build-essential automake libtool pkg-config

cd ~
git clone https://github.com/emscripten-core/emsdk.git && cd emsdk
./emsdk install latest
./emsdk activate latest
source emsdk_env.sh

cd ~
git clone --depth 1 https://github.com/Aloento/FFmpeg4JS --recurse-submodules && cd FFmpeg4JS
make
```

## License

Own library code licensed under LGPL 2.1 or later.
