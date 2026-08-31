# File handling

An image extension alone doesn't establish the file path, declared media type, or size.

`ensureSafeUpload()` requires a plain filename, limits the file size, and checks the extension against an allowed media type. The tests cover a bounded PNG, HTML with an image name, a path disguised as a filename, and an oversized file.
