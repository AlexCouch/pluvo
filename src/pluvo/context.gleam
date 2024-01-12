import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import mist.{type Connection, type ResponseData}
import gleam/bytes_builder
import simplifile

pub type Context{
    Context(request: Request(Connection), resp: Response(ResponseData))
}

fn default_response(){
    response.new(200)
    |> response.set_body(mist.Bytes(bytes_builder.new()))
}

pub fn new(request: Request(Connection)){
    Context(request, default_response())
}

pub fn set_status(ctx: Context, status: Int) -> Response(ResponseData){
    let Response(status: _, headers: headers, body: body) = ctx.resp
    Response(status: status, headers: headers, body: body)
}

pub fn text(ctx: Context, text: String) -> Response(ResponseData){
    let Response(status: status, headers: headers, ..) = ctx.resp
    let body = mist.Bytes(bytes_builder.from_string(text))
    Response(status: status, headers: headers, body: body)
}

pub fn error(ctx: Context, message: String) -> Response(ResponseData){
    let body = mist.Bytes(bytes_builder.from_string(message))
    ctx.resp 
    |> response.set_body(body)
}

pub fn html(ctx: Context, path: String) -> Response(ResponseData){
    case simplifile.read(from: path){
        Ok(data) -> {
            let body = mist.Bytes(bytes_builder.from_string(data))
            ctx.resp 
            |> response.set_body(body)
        }
        Error(_) -> ctx |> error("Failed to get html file: " <> path)
    }
}

pub fn get_method(ctx: Context) -> String{
    ctx.request.method
    |> http.method_to_string
}

pub fn is_method(ctx: Context, method: String) -> Bool{
    get_method(ctx) == method
}
