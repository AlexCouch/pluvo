import gleam/http/response.{type Response}
import mist.{type ResponseData}
import pluvo/context.{type Context}
import gleam/io

pub fn handler(ctx: Context) -> Response(ResponseData) {
  ctx
  |> context.text("Hello, world!")
}
