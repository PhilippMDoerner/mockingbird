<h1> This Package is not finished </h1>

#### _Who's mocking who now?_

This is yet another mocking library.
Unlike other mocking libraries, this one allows you to keep your module structure as it is! 
Just add the `{.mockable.}` pragma to your exported procs, compile with the `--define:mock` flag and you're good to go!

The pragma turns any proc annotated with it into a variable that can be assigned to.
You can then "mock" procs by simply assigning a different procedure to that variable.

**Note: This currently does not work with generics! I'm looking into how to get there but it's hard**

# Example
```nim
# get5Module.nim
proc get5*(): int {.mockable.} = 5 # Can be replaced
```
```nim
# add5Module.nim
import ./get5Module

proc add5*(x: int): int = x + get5()
```

```nim
import ./add5Module
import ./get5Module
import std/[sugar, unittest]


suite "Test add5":  
  # Important for the teardown in order to "reset" the mocks
  let get5Original = get5
  
  teardown:
    get5 = get5Original # "Resets" the mock to provide the normal behaviour again

  test """
    Given get5 returns 5
    When calling add5 with 10
    Then it should return 15
  """:
    check add5(10) == 15

  test """
    Given get5 returns 10
    When calling add5 with 10
    Then it should return 20
  """:
    get5 = () => 10
    check add5(10) == 20

  test """
    Given get5 not being mocked and so it should returns 5
    When calling add5 with 10
    Then it should return 15 again
  """:
    check add5(10) == 15
```