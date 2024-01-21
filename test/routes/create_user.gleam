import pluvo/context.{type Context, type DecodeError, DecodeError}
import pluvo/response.{type Response}
import gleam/option
import gleam/json
import gleam/result
import gleam/dynamic
import gleam/string

pub type User {
  User(name: String, password: String, email: String)
}

pub fn decode_user(data: BitArray) -> Result(User, DecodeError) {
  json.decode_bits(
    from: data,
    using: dynamic.decode3(
      User,
      dynamic.field(named: "name", of: dynamic.string),
      dynamic.field(named: "password", of: dynamic.string),
      dynamic.field(named: "email", of: dynamic.string),
    ),
  )
  |> result.map_error(fn(err) {
    DecodeError(
      err
      |> string.inspect,
    )
  })
}

pub fn handler(ctx: Context) -> Response {
  use user <- context.then(
    ctx
    |> context.bind(decode_user)
    //For now, this needs to be fixed
    |> option.from_result,
  )
  ctx
  |> context.text(user.name)
}
