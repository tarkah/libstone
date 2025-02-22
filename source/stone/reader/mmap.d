/*
 * SPDX-FileCopyrightText: Copyright © 2020-2023 Serpent OS Developers
 *
 * SPDX-License-Identifier: MPL-2.0
 */

/**
 * stone.reader.mmap
 *
 * Make mmap() nice to use from D for reading a file.
 * TODO: Add error handling!
 *
 * Authors: Copyright © 2020-2023 Serpent OS Developers
 * License: MPL-2.0
 */

module stone.reader.mmap;

@safe @nogc nothrow:

import core.sys.posix.fcntl : open, O_RDONLY, O_CLOEXEC;
import core.sys.posix.unistd : close;
import core.sys.posix.sys.mman;
import core.sys.posix.sys.stat;

/** 
 * Map a file and make it usable as a D ubyte[] range
 */
public struct MappedFile
{
    @disable this();
    @disable this(this);

    auto opSlice(size_t start, size_t end) @trusted
    {
        ubyte[] rng = cast(ubyte[])(dataPage[start .. end]);
        return rng;
    }

    auto opDollar() @nogc nothrow => fileSize;

private:

    /** 
     * Construct a new MappedFile
     * Params:
     *   path = Filepath to open
     */
    this(const char* path) @trusted nothrow @nogc
    {
        fd = path.open(O_RDONLY | O_CLOEXEC);
        if (fd < 0)
            return;

        stat_t result;
        if (path.stat(&result) != 0)
            return;
        fileSize = result.st_size;
        dataPage = mmap(null, result.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (dataPage is null)
            return;
    }

    ~this() @trusted nothrow @nogc
    {
        if (fd <= 0)
            return;
        dataPage.munmap(fileSize);
        fd.close;
        fd = 0;
    }

    /* Underlying file descriptor */
    int fd = -1;
    void* dataPage;
    size_t fileSize;
}

auto mappedFile(const char* path) => MappedFile(path);
