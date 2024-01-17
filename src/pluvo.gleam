import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/bytes_builder
import mist.{type Connection, type ResponseData}
import pluvo/router.{type Router, Router}
import gleam/dict
import gleam/option.{None, Some}
import pluvo/context
import pluvo/middleware.{type Middleware}

pub type Pluvo {
  Pluvo(router: Router)
}

pub fn new() -> Pluvo {
  Pluvo(Router(prefix: "", tree: [], routes: dict.new(), middleware: []))
}

pub fn router(pluvo: Pluvo) -> Router {
  pluvo.router
}

pub fn add_router(pluvo: Pluvo, router: Router) -> Pluvo {
  Pluvo(router.join(pluvo.router, router))
}

pub fn enable(pluvo: Pluvo, middleware: Middleware) -> Pluvo {
  pluvo.router
  |> router.enable(middleware)
  |> Pluvo
}

pub fn start(pluvo: Pluvo, port: Int) {
  let selector = process.new_selector()

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      let ctx = context.new(req)

      let route = 
      router.get_route(pluvo.router, req.path) 
      |> router.apply(pluvo.router.middleware)

      ctx
      |> context.add_params(route.method.params)
      |> context.set_path(route.path)
      |> route.method.handler
    }
    |> mist.new
    |> mist.port(port)
    |> mist.start_http

  process.sleep_forever()
}
