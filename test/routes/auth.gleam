import pluvo/context.{type Context}
import mist.{type ResponseData}
import gleam/http/response.{type Response}

pub fn handler(ctx: Context) -> Response(ResponseData) {
  ctx
  |> context.text("Authentication!")
}
