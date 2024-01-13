import pluvo/router.{type RouteHandler, type Router}

pub type Group{
    Group(prefix: String, router: Router)
}

pub fn get(group: Group, path: String, handler: RouteHandler) -> Group{
    let Group(prefix, rt) = group
    let path = prefix <> path
    let rt = rt
    |> router.get(path, handler)
    Group(prefix, rt)
}
