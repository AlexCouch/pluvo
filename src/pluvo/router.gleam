import gleam/dict.{type Dict}
import gleam/string
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/http/response.{type Response}
import mist.{type ResponseData}
import pluvo/context.{type Context}
import pluvo/path.{type Path, Segment, Parameter}
import pluvo/util
import gleam/io

pub type RouteHandler = fn(Context) -> Response(ResponseData)
pub type Route{
    Route(path: Path, method: RouteMethod)
}

//// Provides an interface for creating and registering custom routes
pub type Router{
    Router(prefix: String, tree: List(Node), routes: Dict(Path, Route))
}

pub type MethodKind{
    Get 
    Post 
}

pub type RouteMethod{
    RouteMethod(kind: MethodKind, path: String, params: Dict(String, String), handler: RouteHandler)
}

pub type Node{
    Node(
        path: Path,
        methods: List(RouteMethod),
        is_handler: Bool
    )
}

pub fn new() -> Router{
    with_prefix("")
}

pub fn with_prefix(prefix: String) -> Router{
    Router(prefix: prefix, tree: [], routes: dict.new())
}

fn create_nodes(paths: List(Path), nodes: List(Node)) -> List(Node){
    case paths{
        [first, ..rest] -> {
            let node = Node(first, [], False)
            let nodes = [node, ..nodes]
            create_nodes(rest, nodes)
        }
        _ -> nodes
    }
}

fn is_in_tree(router: Router, node: Node) -> Bool{
    list.contains(router.tree, node)
}

fn append(nodes: List(Node), router: Router) -> Router{
    case nodes{
        [head, ..tail] -> {
            //If the head node is in the tree, then just skip to appending the tail 
            //Otherwise, add the head to the current router tree then append the tail
            let router = {
                //If the head is in the node tree, then leave the router unchanged
                use <- util.when(is_in_tree(router, head), router)
                //Append the current node to the router tree
                let Router(prefix: prefix, tree: tree, routes: routes) = router 
                Router(prefix: prefix, tree: [head, ..tree], routes: routes)
            }
            append(tail, router)
        }
        _ -> router
    }
}

fn add_route(router: Router, path: Path, method: RouteMethod) -> Router{
    let Router(prefix: prefix, tree: tree, routes: routes) = router

    Router(prefix: prefix, tree: tree, routes: dict.insert(into: routes, for: path, insert: Route(path, method)))
}

pub fn add(router: Router, path: String, method: RouteMethod) -> Router{
    let path = path
    |> path.from_string

    path
    |> path.get_all_parents
    |> create_nodes([])
    |> append(router)
    |> add_route(path, method)
}

fn append_prefix(prefix, path: String) -> String{
    //When the prefix is empty, just yield the path
    use <- util.when(string.is_empty(prefix), path)
    let path = {
        use <- util.when(string.starts_with(path, "/"), string.drop_left(path, 1))
        path
    }
    let prefix = {
        use <- util.when(string.ends_with(path, "/"), string.drop_right(path, 1))
        prefix
    }
    prefix <> "/" <> path
}

pub fn get(router: Router, path: String, handler: RouteHandler) -> Router{
    let path = router.prefix 
    |> append_prefix(path)

    let method = RouteMethod(Get, path, dict.new(), handler)
    add(router, path, method)
}

fn compare_param(path: Path, node: Node) -> Bool{
    use <- util.whennot(on: path.is_parameter(node.path), then: False)
    path.shares_parent(path, node.path)
}

fn get_lcp(path: Path, nodes: List(Node)) -> Option(Path){
    case nodes{
        [first, ..rest] -> {
            use <- util.when(on: path.compare(path, first.path), then: Some(first.path))
            use <- util.when(on: compare_param(path, first), then: Some(first.path))
            get_lcp(path, rest)
        }
        _ -> None
    }
}

pub type RouteParameter{
    Parameter(name: String, value: String)
}

pub fn get_param(route: Route, path: Path) -> Option(RouteParameter){
    use <- util.whennot(path.is_parameter(route.path), None)
    case path.last(path), path.last(route.path){
        Some(Segment(value)), Some(path.Parameter(name)) -> Some(Parameter(name, value))
        _, _ -> None
    }
}

pub fn add_params(route: Option(Route), path: Path) -> Option(Route){
    use route <- option.then(route)
    let Route(method: RouteMethod(params: params, kind: kind, handler: handler, path: mpath), ..) = route
    use param <- util.when_none(get_param(route, path), Some(route))

    let params = params
    |> dict.insert(param.name, param.value)

    Route(method: RouteMethod(params: params, kind: kind, handler: handler, path: mpath), path: route.path)
    |> Some
}

pub fn get_route(router: Router, path: String) -> Option(Route){
    let path = path 
    |> path.from_string

    path
    |> get_lcp(router.tree)
    |> option.map(fn(path){
        dict.get(router.routes, path)
        |> option.from_result
    })
    |> option.flatten
    |> add_params(path)
}

pub fn join(router: Router, other: Router) -> Router{
    let Router(_, nodes, routes) = router
    let Router(_, other_nodes, other_routes) = other
    Router("", list.append(nodes, other_nodes), dict.merge(routes, other_routes))
}
