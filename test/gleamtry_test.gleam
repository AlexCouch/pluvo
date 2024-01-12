import pluvo
import pluvo/router
import routes/index
import routes/rand
import routes/html_test

pub fn main() {
    let pluv = pluvo.new()
    
    //Routes
    let routes = pluv 
    |> pluvo.router()
    |> router.get("/", index.handler)
    |> router.get("/rand", rand.handler)
    |> router.get("/html_test", html_test.handler)

    //Init
    pluv
    |> pluvo.add_router(routes)
    |> pluvo.start(3000)
}

