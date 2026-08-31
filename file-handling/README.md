# File handling

The unsafe example trusts a filename because it ends with an image extension. That says nothing about the path or declared media type. It also ignores the file size.

The corrected version checks that the filename is only a filename. It applies a size limit and requires an allowed media type whose extension matches.

The tests accept a bounded PNG. They reject HTML with an image name, a path disguised as a filename, and an oversized file.

