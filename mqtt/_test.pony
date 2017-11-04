use "ponytest"

actor Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    _TestTopic.make().tests(test)
    _TestConnection.make().tests(test)
