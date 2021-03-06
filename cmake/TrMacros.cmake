macro(tr_auto_option_changed NAME ACC VAL FIL STK)
    if(NOT ("${VAL}" STREQUAL "AUTO" OR "${VAL}" STREQUAL "ON" OR "${VAL}" STREQUAL "OFF"))
        if("${VAL}" STREQUAL "0" OR "${VAL}" STREQUAL "NO" OR "${VAL}" STREQUAL "FALSE" OR "${VAL}" STREQUAL "N")
            set_property(CACHE ${NAME} PROPERTY VALUE OFF)
        elseif("${VAL}" MATCHES "^[-+]?[0-9]+$" OR "${VAL}" STREQUAL "YES" OR "${VAL}" STREQUAL "TRUE" OR "${VAL}" STREQUAL "Y")
            set_property(CACHE ${NAME} PROPERTY VALUE ON)
        else()
            message(FATAL_ERROR "Option '${NAME}' set to unrecognized value '${VAL}'. Should be boolean or 'AUTO'.")
        endif()
    endif()
endmacro()

macro(tr_auto_option NAME DESC VAL)
    set(${NAME} "${VAL}" CACHE STRING "${DESC}")
    set_property(CACHE ${NAME} PROPERTY STRINGS "AUTO;ON;OFF")
    variable_watch(${NAME} tr_auto_option_changed)
endmacro()

macro(tr_fixup_auto_option NAME ISFOUND ISREQ)
    if(${ISFOUND})
        set_property(CACHE ${NAME} PROPERTY VALUE ON)
    elseif(NOT (${ISREQ}))
        set_property(CACHE ${NAME} PROPERTY VALUE OFF)
    endif()
endmacro()

macro(tr_get_required_flag IVAR OVAR)
    set(${OVAR})
    if (${IVAR} AND NOT ${IVAR} STREQUAL "AUTO")
        set(${OVAR} REQUIRED)
    endif()
endmacro()

function(tr_make_id INPUT OVAR)
    string(TOUPPER "${INPUT}" ID)
    string(REGEX REPLACE "[^A-Z0-9]+" "_" ID "${ID}")
    string(REGEX REPLACE "^_+|_+$" "" ID "${ID}")
    set(${OVAR} "${ID}" PARENT_SCOPE)
endfunction()

macro(tr_github_upstream ID REPOID RELID RELMD5)
    set(${ID}_RELEASE "${RELID}")
    set(${ID}_UPSTREAM URL "https://github.com/${REPOID}/archive/${RELID}.tar.gz" URL_MD5 "${RELMD5}")
endmacro()

macro(tr_add_external_auto_library ID LIBNAME)
    if(USE_SYSTEM_${ID})
        tr_get_required_flag(USE_SYSTEM_${ID} SYSTEM_${ID}_IS_REQUIRED)
        find_package(${ID} ${${ID}_MINIMUM} ${SYSTEM_${ID}_IS_REQUIRED})
        tr_fixup_auto_option(USE_SYSTEM_${ID} ${ID}_FOUND SYSTEM_${ID}_IS_REQUIRED)
    endif()

    if(USE_SYSTEM_${ID})
        unset(${ID}_UPSTREAM_TARGET)
    else()
        set(${ID}_UPSTREAM_TARGET ${LIBNAME}-${${ID}_RELEASE})
        set(${ID}_PREFIX "${CMAKE_BINARY_DIR}/third-party/${${ID}_UPSTREAM_TARGET}")

        ExternalProject_Add(
            ${${ID}_UPSTREAM_TARGET}
            ${${ID}_UPSTREAM}
            ${ARGN}
            PREFIX "${${ID}_PREFIX}"
            CMAKE_ARGS
                "-DCMAKE_C_FLAGS:STRING=${CMAKE_C_FLAGS}"
                "-DCMAKE_CXX_FLAGS:STRING=${CMAKE_CXX_FLAGS}"
                "-DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}"
                "-DCMAKE_INSTALL_PREFIX:PATH=<INSTALL_DIR>"
        )

        set(${ID}_INCLUDE_DIR "${${ID}_PREFIX}/include" CACHE INTERNAL "")
        set(${ID}_LIBRARY "${${ID}_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}${LIBNAME}${CMAKE_STATIC_LIBRARY_SUFFIX}" CACHE INTERNAL "")

        set(${ID}_INCLUDE_DIRS ${${ID}_INCLUDE_DIR})
        set(${ID}_LIBRARIES ${${ID}_LIBRARY})
    endif()
endmacro()
