import gleam/erlang/process
import gleam/string
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/bytes_builder
import mist.{type Connection, type ResponseData}
import pluvo/router.{type Router, type Route, Route}
import gleam/option.{Some, None}
import pluvo/context.{type Context}

pub type Pluvo{
    Pluvo(router: Router)
}

pub fn new() -> Pluvo{
    Pluvo(router.new())
}

pub fn router(pluvo: Pluvo) -> Router{
    pluvo.router
}

pub fn add_router(pluvo: Pluvo, router: Router) -> Pluvo{
    Pluvo(router.join(pluvo.router, router))
}

pub fn start(pluvo: Pluvo, port: Int){
    let selector = process.new_selector()

    let not_found = 
        response.new(404)
        |> response.set_body(mist.Bytes(bytes_builder.new()))

    let assert Ok(_) =
        fn(req: Request(Connection)) -> Response(ResponseData){
            let ctx = context.new(req)
            case router.get_route(pluvo.router, req.path){
                Some(route) -> {
                    ctx
                    |> context.add_params(route.method.params)
                    |> route.method.handler
                }
                None -> not_found
            }
        }
        |> mist.new 
        |> mist.port(port)
        |> mist.start_http

    process.sleep_forever()
}
