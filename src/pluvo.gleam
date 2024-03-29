import gleam/erlang/process
import gleam/list
import gleam/io
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}
import pluvo/router.{type Router, Router}
import gleam/dict
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
  let new =
    pluvo.router
    |> router.enable(middleware)
    |> Pluvo

  new
}

pub fn start(pluvo: Pluvo, port: Int) {
  let selector = process.new_selector()

  let assert Ok(_) =
    fn(req: Request(Connection)) -> Response(ResponseData) {
      let ctx = context.new(req)

      let route = router.get_route(pluvo.router, req.path)

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
