import pluvo
import pluvo/router
import pluvo/group

import routes/index
import routes/rand
import routes/html_test
import routes/admin_home
import routes/user

pub fn main() {
    let pluv = pluvo.new()
    
    //Routes
    let routes = pluv 
    |> pluvo.router
    |> router.get("/", index.handler)
    |> router.get("/rand", rand.handler)
    |> router.get("/html_test", html_test.handler)
    |> router.get("/user/:id", user.view)

    let auth = pluv 
    |> pluvo.group("/admin")
    // |> group.middleware(jwt.middleware)
    |> group.get("/home", admin_home.handler)

    //Init
    pluv
    |> pluvo.add_router(routes)
    |> pluvo.add_group(auth)
    |> pluvo.start(3000)
}
