import pluvo/middleware.{type Middleware}
import gleam/string
import gleam/option
import pluvo/route.{type RouteHandler}
import pluvo/context.{type Context}
import gleam/http
import gleam/io
import pluvo/request.{type Request}
import pluvo/response.{type Response}
import gleam/int

pub const default_config = Config(
  req_format: "[REQUEST] %h - %s %m %p { %b }",
  resp_format: "[RESPONSE] %h - %s %c %m %p { %b }",
)

pub fn new() -> Middleware {
  logger_mw(default_config, _)
}

pub type Config {
  Config(req_format: String, resp_format: String)
}

pub fn logger_mw(config: Config, next: RouteHandler) -> RouteHandler {
  logger(config, next, _)
}

pub fn format_request(format: String, req: Request) {
  format
  |> string.replace("%h", req.host)
  |> string.replace(
    "%s",
    req.scheme
    |> http.scheme_to_string,
  )
  |> string.replace(
    "%m",
    req.method
    |> http.method_to_string,
  )
  |> string.replace("%p", req.path)
  |> string.replace(
    "%b",
    req
    |> request.get_body
    |> option.unwrap(""),
  )
}

pub fn format_response(format: String, req: Request, resp: Response) -> String {
  format
  |> string.replace("%h", req.host)
  |> string.replace("%p", req.path)
  |> string.replace(
    "%m",
    req.method
    |> http.method_to_string,
  )
  |> string.replace(
    "%s",
    req.scheme
    |> http.scheme_to_string,
  )
  |> string.replace(
    "%c",
    resp.status
    |> int.to_string,
  )
  |> string.replace(
    "%b",
    resp
    |> response.get_body
    |> option.unwrap(""),
  )
}

fn logger(config: Config, next: RouteHandler, ctx: Context) -> Response {
  format_request(config.req_format, ctx.request)
  |> io.println
  let resp = next(ctx)
  format_response(config.resp_format, ctx.request, resp)
  |> io.println
  resp
}
