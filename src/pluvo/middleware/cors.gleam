import gleam/string
import gleam/list
import gleam/io

import pluvo/route
import pluvo/context.{type Context}
import pluvo/response.{type Response}
import pluvo/middleware.{type Middleware}
import pluvo/util

import gleam/http.{Options}

pub type CORSConfig {
  Config(allowed_headers: List(String), allowed_origins: List(String))
}

const allow_access_headers = "Access-Control-Allow-Headers"

const allow_access_origins = "Access-Control-Allow-Origin"

const default_config = Config(allowed_headers: [], allowed_origins: ["*"])

pub fn cors_mw(
  config: CORSConfig,
  handler: route.RouteHandler,
) -> route.RouteHandler {
  //Get the allowed headers and origins
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
    //If the request method is an Options, then it may be a preflight
    case ctx.request.method == Options{
        True -> handle_preflight(allowed_headers, allowed_origins, ctx)
        //If not, do a simple cors check
        False -> handle_cors(allowed_headers, allowed_origins, handler, ctx)
    }
  }
}

fn handle_preflight(allowed_header, allowed_origins: String, ctx: Context) -> Response{
    //TODO: Put "Origin" into global constant
    io.println("Handling preflight")
    use origin <- util.when_some(
        with: ctx |> context.get_header("origin"), 
        //TODO: Create context.no_content
        orelse: ctx 
        |> context.set_status(204)
        |> context.text("")
    )
    use <- util.when(
        on: string.is_empty(allowed_origins),
        then: ctx 
        |> context.set_status(204)
        |> context.text("")
    )
    ctx 
    |> context.set_header("Vary", "Access-Control-Request-Method")
    |> context.set_header("Vary", "Access-Control-Request-Headers")
    |> context.set_header("Vary", "Access-Control-Request-Origin")
    //TOOD: Add logic to verify origin is allowed
    |> check_access_control_request(origin, allowed_header)
}

fn check_access_control_request(ctx: Context, origin, allowed_headers: String) -> Response{
    use acr_headers <- context.then(ctx |> context.get_header("Access-Control-Request-Headers"))
    use acr_method <- context.then(ctx |> context.get_header("Access-Control-Request-Method"))
    let allow_headers = case string.is_empty(allowed_headers){
        True -> acr_headers
        False -> allowed_headers
    }
    //let allow_methods = case string.is_empty(allowed_methods){
    //    True -> aca_headers
    //    False -> allowed_headers
    //}
    let ctx = ctx 
    |> context.set_header("Access-Control-Allow-Headers", allow_headers)
    |> context.set_header("Access-Control-Allow-Methods", acr_method)
    |> context.set_header("Access-Control-Allow-Origin", origin)

    ctx
    |> context.set_status(204)
    |> context.text("")
}

fn handle_cors(allowed_headers, allowed_origins: String, handler: route.RouteHandler, ctx: Context) -> Response{
    ctx
    |> context.set_header(allow_access_headers, allowed_headers)
    |> context.set_header(allow_access_origins, allowed_origins)
    |> handler
}

pub fn new() -> Middleware {
  with_config(default_config)
}

pub fn with_config(config: CORSConfig) -> Middleware {
  cors_mw(config, _)
}
