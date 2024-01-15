import pluvo/context.{type Context}
import gleam/http/response.{type Response}
import mist.{type ResponseData}

pub fn view(ctx: Context) -> Response(ResponseData) {
  use user_id <- context.then(
    ctx
    |> context.get_param("id"),
  )
  ctx
  |> context.text("Hello, user " <> user_id)
}
