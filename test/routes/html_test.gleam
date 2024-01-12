import pluvo/context.{type Context}
import gleam/http/response.{type Response}
import mist.{type ResponseData}

pub fn handler(ctx: Context) -> Response(ResponseData){
    ctx 
    |> context.html("static/views/index.html")
}
