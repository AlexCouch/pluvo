import pluvo/context.{type Context}
import pluvo/path.{type Path}
import pluvo/response.{type Response}

import gleam/dict.{type Dict}

pub type RouteHandler = fn(Context) -> Response
pub type Route{
    Route(path: Path, method: RouteMethod)
}

pub type MethodKind{
    Get 
    Post 
}

pub type RouteMethod{
    RouteMethod(kind: MethodKind, path: String, params: Dict(String, String), handler: RouteHandler)
}

