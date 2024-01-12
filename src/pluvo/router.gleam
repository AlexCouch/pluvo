import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None}
import gleam/string
import gleam/http/response.{type Response}
import mist.{type ResponseData}
import pluvo/context.{type Context}
import gleam/io

pub type RouteHandler = fn(Context) -> Response(ResponseData)
pub type Route{
    Route(path: String, method: RouteMethod)
}

pub type Router{
    Router(tree: List(Node), routes: Dict(String, Route))
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
        prefix: String,
        methods: List(RouteMethod),
        params_child: Option(Node),
        is_handler: Bool
    )
}

pub fn new_router() -> Router{
    Router([], dict.new())
}

fn create_nodes(paths: List(String), nodes: List(Node)) -> List(Node){
    case paths{
        [head, ..tail] -> {
            let nodes = [Node(head, [], None, False), ..nodes]
            create_nodes(tail, nodes)
        }
        _ -> nodes
    }
}

fn get_all_paths(path: List(String), last_path: String, paths: List(String)) -> List(String){
    case path{
        [head, ..tail] -> {
            //TODO: Get request parameters
            let new_path = case head{
                "" -> "/" 
                _ -> case last_path{
                    "" -> "/"
                    _ -> last_path <> head <> "/"
                }
            }
            get_all_paths(tail, new_path, [new_path, ..paths])
        }
        _ -> paths
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

fn add_route(router: Router, path: String, method: RouteMethod) -> Router{
    let Router(tree: tree, routes: routes) = router

    Router(tree: tree, routes: dict.insert(into: routes, for: path, insert: Route(path, method)))
}

pub fn add(router: Router, path: String, method: RouteMethod) -> Router{
    path 
    |> string.split(on: "/")
    |> get_all_paths("", [])
    |> create_nodes([])
    |> append(router)
    |> add_route(path, method)
    router
}

pub fn get(router: Router, path: String, handler: RouteHandler) -> Router{
    let method = RouteMethod(Get, path, [], handler)
    add(router, path, method)
}

pub fn get_route(router: Router, path: String) -> Option(Route){
    io.println("Getting route " <> path)
    dict.get(router.routes, path)
    |> option.from_result
}
