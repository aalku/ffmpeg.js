# [FFmpeg4JS](https://www.npmjs.com/package/ffmpeg4js)

This library provides FFmpeg builds ported to JavaScript using [Emscripten project](https://github.com/emscripten-core/emscripten). Builds are optimized for in-browser use: minimal size for faster loading, asm.js, performance tunings, etc. Though they work in Node as well.

## Builds

### Next (Default)

#### Decoders

| Video | Image | Audio  | RAW       |
| ----- | ----- | ------ | --------- |
| hevc  | jpeg  | vorbis | pcm_s16le |
| vp8   | png   | opus   | pcm_s24le |
| vp9   | webp  | mp3    | pcm_s32le |
| h264  |       | aac    | pcm_s64le |
|       |       | flac   |           |

#### Encoders

| Video      | Audio   |
| ---------- | ------- |
| libvpx_vp9 | libopus |
|            | vorbis  |

### MP4

#### Decoders

#### Encoders

## Version scheme

FFmpeg4JS uses the following version pattern: `major.minor.ddd`, where:

- **major** - FFmpeg's major version number used in the builds.
- **minor** - FFmpeg's minor version.
- **ddd** - FFmpeg4JS patch version.

Current `5.0.14`

## Usage

See documentation on [Module object](https://emscripten.org/docs/api_reference/module.html#affecting-execution) for the list of options that you can pass.

### Via Web Worker

ffmpeg.js also provides wrapper for main function with Web Worker interface to offload the work to a different process. Worker sends the following messages:

- `{type: "ready"}` - Worker loaded and ready to accept commands.
- `{type: "run"}` - Worker started the job.
- `{type: "stdout", data: "<line>"}` - FFmpeg printed to stdout.
- `{type: "stderr", data: "<line>"}` - FFmpeg printed to stderr.
- `{type: "exit", data: "<code>"}` - FFmpeg exited.
- `{type: "done", data: "<result>"}` - Job finished with some result.
- `{type: "error", data: "<error description>"}` - Error occurred.
- `{type: "abort", data: "<abort reason>"}` - FFmpeg terminated abnormally (e.g. out of memory, wasm error).

You can send the following messages to the worker:

- `{type: "run", ...opts}` - Start new job with provided options.

```ts
export default function ExeFFAsync(
  from: string,
  ext: string,
  args: string[],
  buffer: Uint8Array
): Promise<Uint8Array> {
  return new Promise((resolve, reject) => {
    const w = new Worker(new URL("ffmpeg4js", import.meta.url));
    w.onmessage = function (e) {
      const data = e.data;
      const msg = data.data;
      switch (data.type) {
        case "ready":
          w.postMessage({
            type: "run",
            MEMFS: [{ name: from, data: buffer }],
            arguments: args,
          });
          break;
        case "run":
          break;
        case "stdout":
        case "stderr":
          console.info(msg);
          break;
        case "abort":
        case "error":
          console.warn(msg);
          break;
        case "exit":
          console.info(msg);
          break;
        case "done":
          const out = msg.MEMFS.find((x) => x.name === `${from}.${ext}`);
          if (!out) return reject(`${from}.${ext}`);

          resolve(out.data);
          break;
      }
    };
  });
}
```

### Sync run

**Current Not Supported**

```ts
import ffmpeg from "ffmpeg4js";

ffmpeg({
  arguments: ["-version"],
  print: function (data) {
    console.log(data);
  },
  printErr: function (data) {
    console.log(data);
  },
  onExit: function (code) {
    console.log("Process exited with code " + code);
  },
});
```

### Files

Empscripten supports several types of [file systems](https://emscripten.org/docs/api_reference/Filesystem-API.html#file-systems).  
FFmpeg4JS uses [MEMFS](https://emscripten.org/docs/api_reference/Filesystem-API.html#memfs) to store the input/output files in FFmpeg's working directory.  
You need to pass _Array_ of _Object_ to `MEMFS` option with the following keys:

- **name** _(String)_ - File name, can't contain slashes.
- **data** _(ArrayBuffer/ArrayBufferView/Array)_ - File data.

FFmpeg4JS resulting object has `MEMFS` option with the same structure and contains files which weren't passed to the input, i.e. new files created by FFmpeg.

```ts
import ffmpeg from "ffmpeg4js";
import fs from "fs";

const data = new Uint8Array(fs.readFileSync("test.webm"));
// Encode test video to VP8.
const result = ffmpeg({
  MEMFS: [{ name: "test.webm", data: data }],
  arguments: ["-i", "test.webm", "-c:v", "libvpx", "-an", "out.webm"],
});

// Write out.webm to disk.
const out = result.MEMFS[0];
fs.writeFileSync(out.name, Buffer(out.data));
```

You can also mount other FS by passing _Array_ of _Object_ to `mounts` option with the following keys:

- **type** _(String)_ - Name of the file system.
- **opts** _(Object)_ - Underlying file system options.
- **mountpoint** _(String)_ - Mount path, must start with a slash, must not contain other slashes and also the following paths are blacklisted: `/tmp`, `/home`, `/dev`, `/work`. Mount directory will be created automatically before mount.

See documentation of [FS.mount](https://emscripten.org/docs/api_reference/Filesystem-API.html#FS.mount) for more details.

```ts
import ffmpeg from "ffmpeg4js";

ffmpeg({
  // Mount /data inside application to the current directory.
  mounts: [{ type: "NODEFS", opts: { root: "." }, mountpoint: "/data" }],
  arguments: [
    "-i",
    "/data/test.webm",
    "-c:v",
    "libvpx",
    "-an",
    "-y",
    "/data/out.webm",
  ],
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
