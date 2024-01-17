import gleam/string
import gleam/list
import pluvo/route.{type Route}
import pluvo/context.{type Context}
import pluvo/response.{type Response}
import pluvo/middleware.{type Middleware}
import pluvo/util

pub type CORSConfig {
  Config(allowed_headers: List(String), allowed_origins: List(String))
}

const allow_access_headers = "Allow-Access-Headers"

const allow_access_origins = "Allow-Access-Origins"

const default_config = Config(allowed_headers: [], allowed_origins: ["*"])

pub fn cors_mw(
  config: CORSConfig,
  handler: route.RouteHandler,
) -> route.RouteHandler {
  let allowed_headers =
    config.allowed_headers
    |> string.join(",")

  let allowed_origins = {
    use <- util.when(
      list.is_empty(config.allowed_origins),
      default_config.allowed_origins
      |> string.join(","),
    )
    config.allowed_origins
    |> string.join(",")
  }

  fn(ctx: Context) -> Response {
    ctx
    |> context.set_header(allow_access_headers, allowed_headers)
    |> context.set_header(allow_access_origins, allowed_origins)
    |> handler
  }
}

pub fn new() -> Middleware {
  with_config(default_config)
}

pub fn with_config(config: CORSConfig) -> Middleware {
  cors_mw(config, _)
}
