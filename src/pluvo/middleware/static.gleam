import gleam/string
import gleam/option
import gleam/io
import simplifile
import pluvo/middleware.{type Middleware}
import pluvo/route.{type RouteHandler}
import pluvo/context.{type Context}
import pluvo/response.{type Response}
import pluvo/path
import pluvo/util

pub type StaticConfig {
  StaticConfig(root: String)
}

pub fn new(root: String) -> Middleware {
  StaticConfig(root)
  |> with_config
}

pub fn with_config(config: StaticConfig) -> Middleware {
  static_mw(config, _)
}

pub fn static_mw(config: StaticConfig, next: RouteHandler) -> RouteHandler {
  let StaticConfig(root: root) = config
  case root {
    "" -> "."
    _ -> root
  }
  let config = StaticConfig(root)
  static_handler(config, next, _)
}

pub fn static_handler(
  config: StaticConfig,
  next: RouteHandler,
  ctx: Context,
) -> Response {
  io.println("Handling static!")
  //If the config.root has a leading '/', then drop it
  let root = {
    use <- util.when(
      on: string.starts_with(config.root, "/"),
      then: string.drop_left(config.root, 1),
    )
    config.root
  }
  //If the path has the parameter '*' then get the parameter and use it
  let path =
    {
      use <- util.whennot(
        on: path.has_parameter(ctx.path, "*"),
        then: string.append(root, ctx.request.path),
      )
      ctx
      |> context.get_param("*")
      |> option.unwrap("")
      |> string.append(root)
    }
    |> io.debug
  //TODO: Add logic to ignore base
  use <- util.whennot(simplifile.is_file(path), next(ctx))
  use static_contents <- context.then(
    simplifile.read(path)
    |> option.from_result,
  )

  ctx
  |> context.text(static_contents)
}
