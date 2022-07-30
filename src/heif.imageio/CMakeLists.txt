# Copyright 2008-present Contributors to the OpenImageIO project.
# SPDX-License-Identifier: BSD-3-Clause
# https://github.com/OpenImageIO/oiio

if (Libheif_FOUND OR libheif_FOUND)
    add_oiio_plugin (heifinput.cpp heifoutput.cpp
                     INCLUDE_DIRS ${LIBHEIF_INCLUDES} ${libheif_INCLUDES}
                     LINK_LIBRARIES libheif::heif ${LIBHEIF_LIBRARIES} ${libheif_LIBRARIES}
                     DEFINITIONS "-DUSE_HEIF=1")
else ()
    message (WARNING "heif plugin will not be built")
endif ()
