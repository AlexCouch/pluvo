//// Provides an interface for creating and registering custom routes
//// Applies a list of middleware functions to a given Route
//// 
//// The list of Middleware's is recursively applied to the route by
//// capturing each Middleware function with the route to get a new 
//// handler which will replace the old route
//// Applies all midddlewares to all routes in the given Router
//// 
//// This will map the values of the router.routes dict and pipe 
//// each route to the `apply` function with the router's middleware
//// This results in a new dict of routes which have the middleware functions 
//// wrapping the original routes.

import gleam/io
import gleam/dict.{type Dict}
import gleam/string
import gleam/list
import gleam/option.{type Option, None, Some}
import pluvo/context.{type Context}
import pluvo/response.{type Response}
import pluvo/path.{type Path, Parameter, Segment}
import pluvo/route.{
  type Route, type RouteHandler, type RouteMethod, Get, NotFound, Route,
  RouteMethod,
}
import pluvo/util
import pluvo/middleware.{type Middleware}

pub type Router {
  Router(
    prefix: String,
    tree: List(Node),
    routes: Dict(Path, Route),
    middleware: List(Middleware),
  )
}

pub fn route_not_found(ctx: Context) -> Response {
  ctx
  |> context.error(404, "Page does not exist!")
}

pub fn route_not_found_route() -> Route {
  Route(
    "route_not_found"
    |> path.from_string,
    RouteMethod(NotFound, "", dict.new(), route_not_found),
  )
}

pub type Node {
  Node(
    path: Path,
    methods: List(RouteMethod),
    is_handler: Bool,
    not_found: RouteHandler,
  )
}

pub fn prefix(router: Router, prefix: String) -> Router {
  Router(..router, prefix: prefix)
}

pub fn with_prefix(router: Router, other: Router, prefix: String) -> Router {
  let prefix =
    other.prefix
    |> append_prefix(prefix)
  Router(..router, prefix: prefix)
}

fn create_nodes(paths: List(Path), nodes: List(Node)) -> List(Node) {
  case paths {
    [first, ..rest] -> {
      let node = Node(first, [], False, route_not_found)
      let nodes = [node, ..nodes]
      create_nodes(rest, nodes)
    }
    _ -> nodes
  }
}

fn is_in_tree(router: Router, node: Node) -> Bool {
  list.contains(router.tree, node)
}

fn append(nodes: List(Node), router: Router) -> Router {
  case nodes {
    [head, ..tail] -> {
      //If the head node is in the tree, then just skip to appending the tail 
      //Otherwise, add the head to the current router tree then append the tail
      let router = {
        //If the head is in the node tree, then leave the router unchanged
        use <- util.when(is_in_tree(router, head), router)
        //Append the current node to the router tree
        let Router(tree: tree, ..) = router
        Router(..router, tree: [head, ..tree])
      }
      append(tail, router)
    }
    _ -> router
  }
}

fn add_route(router: Router, path: Path, method: RouteMethod) -> Router {
  let Router(routes: routes, ..) = router
  Router(
    ..router,
    routes: dict.insert(into: routes, for: path, insert: Route(path, method)),
  )
}

pub fn apply(route: Route, middleware: List(Middleware)) -> Route {
  use <- util.when(list.is_empty(middleware), route)
  //we can assert because we know this pattern will exist
  let assert [first, ..rest] = middleware
  let handler = first(route.method.handler)
  let method = route.method
  let route = Route(..route, method: RouteMethod(..method, handler: handler))
  apply(route, rest)
}

pub fn apply_middleware(router: Router) -> Router {
  use <- util.when(list.is_empty(router.middleware), router)
  //Map the values of the router.routes with each route piped to `apply`
  let new_routes =
    router.routes
    |> dict.map_values(fn(_, route) {
      route
      |> apply(router.middleware)
    })
  Router(..router, routes: new_routes)
}

///When the middleware list is empty, just return the router as-is
///Apply the route to the router's middleware list
pub fn add(router: Router, path: String, method: RouteMethod) -> Router {
  let path =
    path
    |> path.from_string

  path
  |> path.get_all_parents
  |> create_nodes([])
  |> append(router)
  |> add_route(path, method)
}

fn append_prefix(prefix, path: String) -> String {
  //When the prefix is empty, just yield the path
  use <- util.when(string.is_empty(prefix), path)
  let path = {
    use <- util.when(string.starts_with(path, "/"), string.drop_left(path, 1))
    path
  }
  let prefix = {
    use <- util.when(string.ends_with(prefix, "/"), string.drop_right(prefix, 1),
    )
    prefix
  }
  let new_path = prefix <> "/" <> path
  new_path
  |> io.debug
}

///When the path starts with "/", then drop it
///this will take the prefix and drops the end if it ends with "/"
///When the path ends with "/", then drop it
pub fn get(router: Router, path: String, handler: RouteHandler) -> Router {
  let path =
    router.prefix
    |> append_prefix(path)

  let method = RouteMethod(Get, path, dict.new(), handler)
  add(router, path, method)
}

fn compare_param(path: Path, node: Node) -> Bool {
  use <- util.whennot(on: path.is_parameter(node.path), then: False)
  path.shares_parent(path, node.path)
}

fn get_lcp(path: Path, nodes: List(Node)) -> Option(Node) {
  case nodes {
    [first, ..rest] -> {
      use <- util.when(on: path.compare(path, first.path), then: Some(first))
      use <- util.when(on: compare_param(path, first), then: Some(first))
      get_lcp(path, rest)
    }
    _ -> None
  }
}

pub type RouteParameter {
  Parameter(name: String, value: String)
}

pub fn get_param(route: Route, path: Path) -> Option(RouteParameter) {
  use <- util.whennot(path.is_parameter(route.path), None)
  case path.last(path), path.last(route.path) {
    Some(Segment(value)), Some(path.Parameter(name)) ->
      Some(Parameter(name, value))
    _, _ -> None
  }
}

pub fn add_params(route: Option(Route), path: Path) -> Option(Route) {
  use route <- option.then(route)
  let Route(
    method: RouteMethod(
      params: params,
      kind: kind,
      handler: handler,
      path: mpath,
    ),
    ..,
  ) = route
  use param <- util.when_none(get_param(route, path), Some(route))

  let params =
    params
    |> dict.insert(param.name, param.value)

  Route(
    method: RouteMethod(
      params: params,
      kind: kind,
      handler: handler,
      path: mpath,
    ),
    path: route.path,
  )
  |> Some
}

pub fn get_route(router: Router, path: String) -> Route {
  let path =
    path
    |> path.from_string

  path
  |> get_lcp(router.tree)
  |> option.map(fn(node) {
    dict.get(router.routes, node.path)
    |> option.from_result
    |> option.or(
      Some(Route(
        node.path,
        RouteMethod(NotFound, "", dict.new(), node.not_found),
      )),
    )
  })
  |> option.flatten
  |> add_params(path)
  |> option.unwrap(route_not_found_route())
}

pub fn join(router: Router, other: Router) -> Router {
  let Router(_, nodes, routes, mw) = router
  let Router(_, other_nodes, other_routes, other_mw) = other
  Router(
    "",
    list.append(nodes, other_nodes),
    dict.merge(routes, other_routes),
    list.append(mw, other_mw),
  )
}

pub fn enable(router: Router, middleware: Middleware) -> Router {
  Router(..router, middleware: [middleware, ..router.middleware])
}
