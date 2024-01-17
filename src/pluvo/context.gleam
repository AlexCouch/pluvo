import gleam/http
import gleam/http/cookie as http_cookie
import gleam/result
import gleam/io
import gleam/list
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import mist.{type Connection, type ResponseData}
import gleam/bytes_builder
import simplifile
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import pluvo/cookie.{type Cookie, Cookie}
import pluvo/util

pub type Context {
  Context(
    request: Request(Connection),
    resp: Response(ResponseData),
    params: Dict(String, String),
  )
}

fn default_response() {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.new()))
}

pub fn new(request: Request(Connection)) {
  Context(request, default_response(), dict.new())
}

pub fn set_status(ctx: Context, status: Int) -> Response(ResponseData) {
  let Response(status: _, headers: headers, body: body) = ctx.resp
  Response(status: status, headers: headers, body: body)
}

pub fn text(ctx: Context, text: String) -> Response(ResponseData) {
  let Response(status: status, headers: headers, ..) = ctx.resp
  let body = mist.Bytes(bytes_builder.from_string(text))
  Response(status: status, headers: headers, body: body)
}

pub fn error(ctx: Context, message: String) -> Response(ResponseData) {
  let body = mist.Bytes(bytes_builder.from_string(message))
  ctx.resp
  |> response.set_body(body)
}

pub fn html(ctx: Context, path: String) -> Response(ResponseData) {
  use data <- util.when_ok(
    simplifile.read(from: path),
    ctx
    |> error("Failed to get html file: " <> path),
  )
  let body = mist.Bytes(bytes_builder.from_string(data))
  ctx.resp
  |> response.set_body(body)
}

pub fn get_method(ctx: Context) -> String {
  ctx.request.method
  |> http.method_to_string
}

pub fn is_method(ctx: Context, method: String) -> Bool {
  get_method(ctx) == method
}

pub fn get_param(ctx: Context, key: String) -> Option(String) {
  dict.get(ctx.params, key)
  |> option.from_result
}

pub fn add_param(ctx: Context, key: String, value: String) -> Context {
  let Context(request: req, resp: resp, params: params) = ctx
  Context(req, resp, dict.insert(params, key, value))
}

pub fn add_params(ctx: Context, params: Dict(String, String)) -> Context {
  let Context(request: req, resp: resp, params: ctxparams) = ctx
  Context(req, resp, dict.merge(ctxparams, params))
}

pub fn new_cookie(ctx: Context) -> Cookie {
  http_cookie.defaults(ctx.request.scheme)
  |> Cookie("", "")
}

pub fn set_cookie(ctx: Context, cookie: Cookie) -> Context {
  let resp =
    ctx.resp
    |> response.set_cookie(cookie.name, cookie.value, cookie.attributes)

  Context(..ctx, resp: resp)
}

pub fn get_cookie(ctx: Context, name: String) -> Option(String) {
  ctx.request
  |> request.get_cookies
  |> list.find(fn(cookie) { cookie.0 == name })
  |> result.map(fn(cookie) { cookie.1 })
  |> option.from_result
}

pub fn set_header(ctx: Context, name: String, value: String) -> Context {
  let resp =
    ctx.resp
    |> response.set_header(name, value)
  Context(..ctx, resp: resp)
}

pub fn get_header(ctx: Context, name: String) -> Option(String) {
  ctx.request
  |> request.get_header(name)
  |> option.from_result
}

///Apply a callback onto a result object if it exists, returning data to send back to the client
///This allows route handlers to simplify the calls of various get functions such as get_parameter
///and replace the case expression with a use statement to reduce code.
pub fn then(
  result: Option(a),
  fun: fn(a) -> Response(ResponseData),
) -> Response(ResponseData) {
  case result {
    Some(dat) -> {
      fun(dat)
    }
    None -> {
      let body = mist.Bytes(bytes_builder.from_string("Something went wrong!"))
      response.new(404)
      |> response.set_body(body)
    }
  }
}
