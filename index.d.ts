// Type definitions for package FFmpeg4JS 4.4
// Project: https://github.com/Aloento/FFmpeg4JS.git
// Definitions by: Vladimir Grenaderov <https://github.com/VladimirGrenaderov>,
//                 Max Boguslavskiy <https://github.com/maxbogus>
// Definitions: https://github.com/DefinitelyTyped/DefinitelyTyped
// TypeScript Version: 3.0

declare namespace ffmpeg {
    interface Options {
        arguments: string[];
        MEMFS?: Video[] | undefined;
        print?(data: any): void;
        printErr?(data: any): void;
        onExit?(code: unknown): void;
        stdin?(data: any): void;
        mounts?: Mount[] | undefined;
        TOTAL_MEMORY?: number | undefined;
    }

    interface Opts {
        root: string;
    }

    interface Mount {
        type: string;
        opts: Opts;
        mountpoint: string;
    }

    interface Result {
        MEMFS: Video[];
    }

    interface Video {
        data: Uint8Array;
        name: string;
    }

    namespace Worker {
        interface Type {
            "ready",
            "run",
            "stdout",
            "stderr",
            "abort",
            "error",
            "exit",
            "done"
        }

        interface Data {
            type: keyof Type;
            data: string;
        }

        interface PostMessageOptions {
            type: string;
            arguments: string[];
            MEMFS?: Video[] | undefined;
            mounts?: Mount[] | undefined;
            TOTAL_MEMORY?: number | undefined;
        }

        interface OnMessageOptions {
            data: Data;
        }
    }

    function ffmpeg(opts: Options): Result;

    class Worker {
        constructor(someParam?: string);

        onmessage(opts: Worker.OnMessageOptions): void;
        postMessage(opts: Worker.PostMessageOptions): void;
        terminate(): void;
    }
}

declare function ffmpeg(opts: ffmpeg.Options): ffmpeg.Result;

export = ffmpeg;
