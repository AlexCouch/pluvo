import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
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
}

pub fn get(router: Router, path: String, handler: RouteHandler) -> Router{
    let method = RouteMethod(Get, path, [], handler)
    add(router, path, method)
}

fn find_lcp(paths: List(String), path: String, lcp: String) -> Option(String){
    case paths{
        [head, ..tail] ->{
            case string.starts_with(path, head){
                True -> {
                    //We need to change the lcp to the head in the event that 
                    // the length of the head is longer than the current lcp
                    let lcp = case string.length(head) > string.length(lcp){
                        True -> head
                        False -> lcp
                    }
                    find_lcp(tail, path, lcp)
                }
                //Otherwise, continue finding the lcp with nothing changed
                False -> find_lcp(tail, path, lcp)
            }
        }
        _ -> case lcp{
            ""  -> None
            _   -> Some(lcp)
        }
    }
}

fn get_lcp(router: Router, path: String) -> Option(Route){
    let Router(routes: routes, ..) = router
    let paths = dict.keys(routes)
    find_lcp(paths, path, "")
    |> option.map(fn(lcp) {
        routes 
        |> dict.get(lcp)
        |> option.from_result
    })
    |> option.flatten
}

pub fn get_route(router: Router, path: String) -> Option(Route){
    //Get the longest common part between the request path and the registered paths
    let lcp = get_lcp(router, path)
    io.debug(lcp)
}

pub fn join(router: Router, other: Router) -> Router{
    let Router(nodes, routes) = router
    let Router(other_nodes, other_routes) = other
    Router(list.append(nodes, other_nodes), dict.merge(routes, other_routes))
}
