import pluvo/context.{type Context}
import pluvo/response.{type Response}

pub fn handler(ctx: Context) -> Response{
    use count <- context.then(ctx |> context.get_param("count"))
    ctx 
    |> context.text("count: " <> count)
}
