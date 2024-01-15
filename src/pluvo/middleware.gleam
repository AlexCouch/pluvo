import pluvo/response.{type Response}
import pluvo/route.{type Route}
import pluvo/context.{type Context}

pub type Middleware =
  fn(Route, Context) -> Response
