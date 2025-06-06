#if defined(LIBCO_C)

/*[amd64, arm, ppc, x86]:
   by default, co_swap_function is marked as a text (code) section
   if not supported, uncomment the below line to use mprotect instead */
/* #define LIBCO_MPROTECT */

/*[amd64]:
   Win64 only: provides a substantial speed-up, but will thrash XMM regs
   do not use this unless you are certain your application won't use SSE */
/* #define LIBCO_NO_SSE */

/*[amd64, aarch64]:
   Win64 only: provides a small speed-up, but will break stack unwinding
   do not use this if your application uses exceptions or setjmp/longjmp */
/* #define LIBCO_NO_TIB */

#if defined(LIBCO_C)
  #if defined(LIBCO_MP)
    #define thread_local __thread
  #else
    #define thread_local
  #endif
#endif

#if __STDC_VERSION__ >= 201112L
  #if !defined(_MSC_VER)
    #include <stdalign.h>
  #endif
#else
  #define alignas(bytes)
#endif

#if defined(_MSC_VER)
  #pragma section(".text")
  #define section(name) __declspec(allocate(".text"))
#elif defined(__APPLE__)
  #define section(name) __attribute__((section("__TEXT,__" #name)))
#else
  #define section(name) __attribute__((section("." #name "#")))
#endif

#if defined(__clang__)
  #pragma clang diagnostic ignored "-Wparentheses"

  #if !defined(_MSC_VER)
    /* placing code in section(text) does not mark it executable with Clang. */
    #undef  LIBCO_MPROTECT
    #define LIBCO_MPROTECT
  #endif
#endif

#if defined(__aarch64__)
  /* NX also seems to be consistently set under non-Windows arm64  */
  #if !defined(_MSC_VER)
    #undef  LIBCO_MPROTECT
    #define LIBCO_MPROTECT
  #endif
#endif

/* if defined(LIBCO_C) */
#endif
