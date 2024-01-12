import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/bytes_builder
import mist.{type Connection, type ResponseData}
import router.{type Router}
import gleam/option.{Some, None}
import context

pub type Pluvo{
    Pluvo(router: Router)
}

pub fn new() -> Pluvo{
    Pluvo(router.new_router())
}

pub fn router(pluvo: Pluvo) -> Router{
    pluvo.router
}

//Note: pluvo is passed in for api design and future proofing
pub fn add_router(_pluvo: Pluvo, router: Router) -> Pluvo{
    Pluvo(router)
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
                Some(route) -> route.method.handler(ctx)
                None -> context.error(ctx, "Could not find route " <> req.path)
            }
        }
        |> mist.new 
        |> mist.port(port)
        |> mist.start_http

    process.sleep_forever()
}
