use "files"
use "mqtt"
use "net/ssl"

class iso MQTTTLSNotify is MQTTConnectionNotify
  """
  Attempt to connect to a TLS-secure server using a certificate authority file.
  """

  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref on_connect(conn: MQTTConnection ref, session_present: Bool) =>
    _env.out.print("Success.")
    conn.disconnect()

  fun ref on_error(
    conn: MQTTConnection ref, err: MQTTError, info: Array[U8] val)
  =>
    _env.out.print("Error: " + err.string())

actor Main
  new create(env: Env) =>
    try
      let auth = env.root as AmbientAuth
      let sslctx: SSLContext =
        recover
          let cert = FilePath(auth, "./cert.pem")?
          SSLContext
            .> set_authority(cert)?
            .> set_client_verify(true)
        end
      MQTTConnection(
        auth,
        MQTTTLSNotify(env),
        "test.mosquitto.org",
        "8883"
        where sslctx' = sslctx)
    else
      env.out.print("Error when creating SSLContext")
    end
