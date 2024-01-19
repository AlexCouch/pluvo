import pluvo/middleware.{type Middleware}
import pluvo/path
import pluvo/route.{type RouteHandler}
import pluvo/context.{type Context}
import gleam/string_builder
import gleam/http
import gleam/io

pub fn new() -> Middleware {
  logger_mw
}

pub fn logger_mw(next: RouteHandler) -> RouteHandler {
  fn(ctx: Context) {
    string_builder.new()
    |> string_builder.append("[LOG] ")
    |> string_builder.append(
      ctx.request.method
      |> http.method_to_string,
    )
    |> string_builder.append(" request from ")
    |> string_builder.append(ctx.request.host)
    |> string_builder.append(" to ")
    |> string_builder.append(
      ctx.path
      |> path.to_string,
    )
    |> string_builder.to_string
    |> io.println
    next(ctx)
  }
}
