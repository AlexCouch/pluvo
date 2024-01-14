import pluvo/context.{type Context}
import gleam/http/response.{type Response}
import mist.{type ResponseData}

pub fn view(ctx: Context) -> Response(ResponseData){
    ctx 
    |> context.text("User id here!")
}
