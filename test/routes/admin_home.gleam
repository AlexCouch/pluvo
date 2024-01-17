import pluvo/context.{type Context}
import mist.{type ResponseData}
import gleam/http/response.{type Response}

pub fn handler(ctx: Context) -> Response(ResponseData) {
  use qtest <- context.then(
    ctx
    |> context.get_query_param("test"),
  )

  ctx
  |> context.text("test = " <> qtest)
}
