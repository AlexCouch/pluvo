import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/bytes_builder
import mist.{type Connection, type ResponseData}
import pluvo/router.{type Router, RouteContext}
import gleam/option.{Some, None}
import pluvo/context
import pluvo/group.{type Group, Group}

pub type Pluvo{
    Pluvo(router: Router)
}

pub fn new() -> Pluvo{
    Pluvo(router.new_router())
}

pub fn router(pluvo: Pluvo) -> Router{
    pluvo.router
}

pub fn group(pluvo: Pluvo, prefix: String) -> Group{
    Group(prefix, pluvo.router)
}

pub fn add_group(pluvo: Pluvo, group: group.Group) -> Pluvo{
    Pluvo(router.join(pluvo.router, group.router))
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
            case router.get_route(ctx, pluvo.router, req.path){
                Some(RouteContext(route, ctx)) -> route.method.handler(ctx)
                None -> not_found
            }
        }
        |> mist.new 
        |> mist.port(port)
        |> mist.start_http

    process.sleep_forever()
}
