import pluvo
import pluvo/router
import routes/index
import routes/rand
import routes/html_test
import routes/admin_home
import routes/user
import routes/count
import pluvo/route.{type Route}
import pluvo/response.{type Response}
import pluvo/context.{type Context}
import gleam/io

pub fn my_middleware(route: Route, ctx: Context) -> Response {
  io.println("Hello, from my_middleware!")
  ctx
  |> context.add_param("count", "5")
  |> route.method.handler
}

pub fn main() {
  let pluv =
    pluvo.new()
    |> pluvo.enable(my_middleware)

  //Routes
  let routes =
    pluv
    |> pluvo.router
    |> router.get("/", index.handler)
    |> router.get("/rand", rand.handler)
    |> router.get("/html_test", html_test.handler)
    |> router.get("/user/:id", user.view)
    |> router.get("/count", count.handler)

  let auth =
    pluv
    |> pluvo.router
    |> router.prefix("/admin")
    |> router.get("/home", admin_home.handler)

  //Init
  pluv
  |> pluvo.add_router(routes)
  |> pluvo.add_router(auth)
  |> pluvo.start(3000)
}
