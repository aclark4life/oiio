# Copyright 2008-present Contributors to the OpenImageIO project.
# SPDX-License-Identifier: BSD-3-Clause
# https://github.com/OpenImageIO/oiio

if (LIBRAW_FOUND OR libraw_FOUND)
    add_oiio_plugin (rawinput.cpp
                     INCLUDE_DIRS ${LIBRAW_INCLUDE_DIR} ${libraw_INCLUDE_DIR}
                     LINK_LIBRARIES ${LIBRAW_LIBRARIES} ${libraw_LIBRARIES}
                     DEFINITIONS "-DUSE_LIBRAW=1" ${libraw_r_DEFINITIONS} $<$<AND:$<PLATFORM_ID:Windows>,$<BOOL:${LINKSTATIC}>>:LIBRAW_NODLL=1>)
else ()
    message (WARNING "Raw plugin will not be built")
endif ()
