import gleam/http/response.{type Response}
import mist.{type ResponseData}
import gleam/int
import pluvo/context.{type Context}

pub fn handler(ctx: Context) -> Response(ResponseData) {
  let content =
    int.random(10)
    |> int.to_string

  ctx
  |> context.text(content)
}
