template mockTearDown

template initMockEnvironment(procs: varargs[untyped]) =
  echo procs.len