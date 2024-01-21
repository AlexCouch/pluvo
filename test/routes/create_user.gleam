import pluvo/context.{type Context}
import pluvo/response.{type Response}
import gleam/dynamic

pub type User {
  User(name: String, password: String, email: String)
}

pub fn user_decoder() {
  dynamic.decode3(
    User,
    dynamic.field(named: "name", of: dynamic.string),
    dynamic.field(named: "password", of: dynamic.string),
    dynamic.field(named: "email", of: dynamic.string),
  )
}

pub fn handler(ctx: Context) -> Response {
  let bind =
    ctx
    |> context.bind_json(user_decoder())
  case bind {
    Ok(user) ->
      ctx
      |> context.text(user.name)
    Error(err) ->
      ctx
      |> context.error(503, err.message)
  }
}
