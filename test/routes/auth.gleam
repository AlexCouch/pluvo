import pluvo/context.{type Context}
import mist.{type ResponseData}
import gleam/http/response.{type Response}
import pluvo/cookie

pub fn handler(ctx: Context) -> Response(ResponseData) {
    let cookie =
    ctx
    |> context.new_cookie
    |> cookie.set("test", "sup")
    |> cookie.expires(60 * 5)

    ctx 
    |> context.set_cookie(cookie)
    |> context.text("Authentication!")
}
