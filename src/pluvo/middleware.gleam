import pluvo/route

pub type Middleware =
  fn(route.RouteHandler) -> route.RouteHandler
