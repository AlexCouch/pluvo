import pluvo/response.{type Response}
import pluvo/context.{type Context}
import gleam/json
import gleam/string
import simplifile

const filepath = "tests/db.json"

pub fn handler(ctx: Context) -> Response {
  use username <- context.then(
    ctx
    |> context.form_data("username"),
  )

  use password <- context.then(
    ctx
    |> context.form_data("password"),
  )

  let json =
    json.object([
      #("username", json.string(username)),
      #("password", json.string(password)),
    ])
    |> json.to_string

  case
    json
    |> simplifile.write(to: filepath)
  {
    Ok(_) ->
      ctx
      |> context.text("Successfully logged in!")
    Error(err) -> {
      let message =
        err
        |> string.inspect
      ctx
      |> context.error(503, message)
    }
  }
}
