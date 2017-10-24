use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  // TODO: Real tests
  fun tag tests(test: PonyTest) =>
    test(_TestStub)

class _TestStub is UnitTest
  fun name(): String =>
    "mqtt/Stub"

  fun ref apply(h: TestHelper) =>
    None
