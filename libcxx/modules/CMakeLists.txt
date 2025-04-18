# The headers of Table 24: C++ library headers [tab:headers.cpp]
# and the headers of Table 25: C++ headers for C library facilities [tab:headers.cpp.c]
set(LIBCXX_MODULE_STD_SOURCES
  std/algorithm.inc
  std/any.inc
  std/array.inc
  std/atomic.inc
  std/barrier.inc
  std/bit.inc
  std/bitset.inc
  std/cassert.inc
  std/cctype.inc
  std/cerrno.inc
  std/cfenv.inc
  std/cfloat.inc
  std/charconv.inc
  std/chrono.inc
  std/cinttypes.inc
  std/climits.inc
  std/clocale.inc
  std/cmath.inc
  std/codecvt.inc
  std/compare.inc
  std/complex.inc
  std/concepts.inc
  std/condition_variable.inc
  std/coroutine.inc
  std/csetjmp.inc
  std/csignal.inc
  std/cstdarg.inc
  std/cstddef.inc
  std/cstdint.inc
  std/cstdio.inc
  std/cstdlib.inc
  std/cstring.inc
  std/ctime.inc
  std/cuchar.inc
  std/cwchar.inc
  std/cwctype.inc
  std/deque.inc
  std/exception.inc
  std/execution.inc
  std/expected.inc
  std/filesystem.inc
  std/flat_map.inc
  std/flat_set.inc
  std/format.inc
  std/forward_list.inc
  std/fstream.inc
  std/functional.inc
  std/future.inc
  std/generator.inc
  std/hazard_pointer.inc
  std/initializer_list.inc
  std/iomanip.inc
  std/ios.inc
  std/iosfwd.inc
  std/iostream.inc
  std/istream.inc
  std/iterator.inc
  std/latch.inc
  std/limits.inc
  std/list.inc
  std/locale.inc
  std/map.inc
  std/mdspan.inc
  std/memory.inc
  std/memory_resource.inc
  std/mutex.inc
  std/new.inc
  std/numbers.inc
  std/numeric.inc
  std/optional.inc
  std/ostream.inc
  std/print.inc
  std/queue.inc
  std/random.inc
  std/ranges.inc
  std/ratio.inc
  std/rcu.inc
  std/regex.inc
  std/scoped_allocator.inc
  std/semaphore.inc
  std/set.inc
  std/shared_mutex.inc
  std/source_location.inc
  std/span.inc
  std/spanstream.inc
  std/sstream.inc
  std/stack.inc
  std/stacktrace.inc
  std/stdexcept.inc
  std/stdfloat.inc
  std/stop_token.inc
  std/streambuf.inc
  std/string.inc
  std/string_view.inc
  std/strstream.inc
  std/syncstream.inc
  std/system_error.inc
  std/text_encoding.inc
  std/thread.inc
  std/tuple.inc
  std/type_traits.inc
  std/typeindex.inc
  std/typeinfo.inc
  std/unordered_map.inc
  std/unordered_set.inc
  std/utility.inc
  std/valarray.inc
  std/variant.inc
  std/vector.inc
  std/version.inc
)

set(LIBCXX_MODULE_STD_COMPAT_SOURCES
  std.compat/cassert.inc
  std.compat/cctype.inc
  std.compat/cerrno.inc
  std.compat/cfenv.inc
  std.compat/cfloat.inc
  std.compat/cinttypes.inc
  std.compat/climits.inc
  std.compat/clocale.inc
  std.compat/cmath.inc
  std.compat/csetjmp.inc
  std.compat/csignal.inc
  std.compat/cstdarg.inc
  std.compat/cstddef.inc
  std.compat/cstdint.inc
  std.compat/cstdio.inc
  std.compat/cstdlib.inc
  std.compat/cstring.inc
  std.compat/ctime.inc
  std.compat/cuchar.inc
  std.compat/cwchar.inc
  std.compat/cwctype.inc
)

set(LIBCXX_MODULE_STD_INCLUDE_SOURCES)
foreach(file ${LIBCXX_MODULE_STD_SOURCES})
  set(
    LIBCXX_MODULE_STD_INCLUDE_SOURCES
    "${LIBCXX_MODULE_STD_INCLUDE_SOURCES}#include \"${file}\"\n"
  )
endforeach()

configure_file(
  "std.cppm.in"
  "${LIBCXX_GENERATED_MODULE_DIR}/std.cppm"
  @ONLY
)

set(LIBCXX_MODULE_STD_COMPAT_INCLUDE_SOURCES)
foreach(file ${LIBCXX_MODULE_STD_COMPAT_SOURCES})
  set(
    LIBCXX_MODULE_STD_COMPAT_INCLUDE_SOURCES
    "${LIBCXX_MODULE_STD_COMPAT_INCLUDE_SOURCES}#include \"${file}\"\n"
  )
endforeach()

configure_file(
  "std.compat.cppm.in"
  "${LIBCXX_GENERATED_MODULE_DIR}/std.compat.cppm"
  @ONLY
)

set(_all_modules)
list(APPEND _all_modules "${LIBCXX_GENERATED_MODULE_DIR}/std.cppm")
list(APPEND _all_modules "${LIBCXX_GENERATED_MODULE_DIR}/std.compat.cppm")
foreach(file ${LIBCXX_MODULE_STD_SOURCES} ${LIBCXX_MODULE_STD_COMPAT_SOURCES})
  set(src "${CMAKE_CURRENT_SOURCE_DIR}/${file}")
  set(dst "${LIBCXX_GENERATED_MODULE_DIR}/${file}")
  add_custom_command(OUTPUT ${dst}
    DEPENDS ${src}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${src} ${dst}
    COMMENT "Copying CXX module ${file}")
  list(APPEND _all_modules "${dst}")
endforeach()

add_custom_target(generate-cxx-modules
  ALL DEPENDS
    ${_all_modules}
)
