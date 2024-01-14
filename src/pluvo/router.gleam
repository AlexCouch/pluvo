import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/http/response.{type Response}
import mist.{type ResponseData}
import pluvo/context.{type Context}
import gleam/io
import pluvo/path.{type Path}

pub type RouteHandler = fn(Context) -> Response(ResponseData)
pub type Route{
    Route(path: Path, method: RouteMethod)
}

//// Provides an interface for creating and registering custom routes
pub type Router{
    Router(tree: List(Node), routes: Dict(Path, Route))
}

pub type MethodKind{
    Get 
    Post 
}

pub type RouteMethod{
    RouteMethod(kind: MethodKind, path: String, param_names: List(String), handler: RouteHandler)
}

pub type Node{
    Node(
        path: Path,
        methods: List(RouteMethod),
        is_handler: Bool
    )
}

pub fn new_router() -> Router{
    Router([], dict.new())
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
            let router = case is_in_tree(router, head){
                False -> {
                    //Append the current node to the router tree
                    let Router(tree: tree, routes: routes) = router 
                    Router(tree: [head, ..tree], routes: routes)
                }
                //Return the router unchanged
                True -> router
            }
            append(tail, router)
        }
        _ -> router
    }
}

fn add_route(router: Router, path: Path, method: RouteMethod) -> Router{
    let Router(tree: tree, routes: routes) = router

    Router(tree: tree, routes: dict.insert(into: routes, for: path, insert: Route(path, method)))
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

pub fn get(router: Router, path: String, handler: RouteHandler) -> Router{
    let method = RouteMethod(Get, path, [], handler)
    add(router, path, method)
}

fn compare_param(path: Path, node: Node) -> Bool{
    case path.is_parameter(node.path){
        False -> False
        True -> path.shares_parent(path, node.path)
    }
}

fn get_lcp(path: Path, nodes: List(Node)) -> Option(Path){
    case nodes{
        [first, ..rest] -> {
            case path.compare(path, first.path){
                True -> Some(first.path)
                False -> {
                    case compare_param(path, first){
                        True -> Some(first.path)
                        False -> get_lcp(path, rest)
                    }
                }
            }
        }
        _ -> None
    }
}

pub fn get_route(router: Router, path: String) -> Option(Route){
    path 
    |> path.from_string
    |> get_lcp(router.tree)
    |> option.map(fn(path){
        dict.get(router.routes, path)
        |> option.from_result
    })
    |> option.flatten
}

pub fn join(router: Router, other: Router) -> Router{
    let Router(nodes, routes) = router
    let Router(other_nodes, other_routes) = other
    Router(list.append(nodes, other_nodes), dict.merge(routes, other_routes))
}
