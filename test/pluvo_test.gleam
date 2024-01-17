import pluvo.{type Pluvo}
import pluvo/router
import routes/index
import routes/rand
import routes/html_test
import routes/user
import routes/auth
import routes/admin_home
import pluvo/route.{type Route}
import pluvo/response.{type Response}
import pluvo/context.{type Context}
import gleam/io

pub fn my_middleware(route: Route, ctx: Context) -> Response {
  ctx
  |> context.get_header("Accept-Language")
  |> io.debug

  ctx
  |> route.method.handler
}

pub fn v1(pluv: Pluvo) -> Pluvo {
  let api =
    pluv
    |> pluvo.router
    |> router.prefix("api/v1/")
    |> router.get("/", index.handler)
    |> router.get("/rand", rand.handler)
    |> router.get("/html_test", html_test.handler)
    |> router.get("/auth", auth.handler)

  let user =
    pluv
    |> pluvo.router
    |> router.with_prefix(api, "user")
    |> router.get("/:id", user.handler)

  let admin =
    pluv
    |> pluvo.router
    |> router.with_prefix(api, "admin")
    |> router.get("/home", admin_home.handler)

  pluv
  |> pluvo.add_router(api)
  |> pluvo.add_router(user)
  |> pluvo.add_router(admin)
}

pub fn main() {
  pluvo.new()
  |> pluvo.enable(my_middleware)
  |> v1
  |> pluvo.start(3000)
}
