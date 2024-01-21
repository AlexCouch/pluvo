import pluvo.{type Pluvo}
import pluvo/router
import routes/index
import routes/rand
import routes/html_test
import routes/user
import routes/auth
import routes/admin_home
import pluvo/middleware/cors
import pluvo/middleware/static
import pluvo/middleware/logger
import routes/create_user

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
    |> router.post("/create", create_user.handler)

  let cors_admin =
    cors.Config(
      allowed_headers: ["access-authentication-test-route", "content-type"],
      allowed_origins: [],
    )
    |> cors.with_config

  let admin =
    pluv
    |> pluvo.router
    |> router.with_prefix(api, "admin")
    |> router.get("/home", admin_home.handler)
    |> router.post("/home", admin_home.handler)
    |> router.enable(cors_admin)

  pluv
  |> pluvo.add_router(api)
  |> pluvo.add_router(user)
  |> pluvo.add_router(admin)
}

pub fn main() {
  let cors = cors.new()
  let static = static.new("/static")

  let pluv =
    pluvo.new()
    |> pluvo.enable(logger.new())
    |> pluvo.enable(static)

  let root =
    pluv
    |> pluvo.router
    |> router.enable(cors)
    |> router.post("/", index.handler)
  pluv
  |> v1
  |> pluvo.add_router(root)
  |> pluvo.start(3000)
}
