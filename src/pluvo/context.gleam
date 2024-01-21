import gleam/http
import gleam/string
import gleam/int
import gleam/dynamic
import gleam/json
import gleam/http/cookie as http_cookie
import gleam/result
import gleam/list
import gleam/bytes_builder
import simplifile
import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import pluvo/cookie.{type Cookie, Cookie}
import pluvo/util
import pluvo/path.{type Path}
import gleam/http/request as http_req
import pluvo/request.{type Request}
import pluvo/response.{type Response}
import gleam/http/response as http_resp
import mist
import gleam/bit_array

pub type Context {
  Context(
    request: Request,
    resp: Response,
    path: Path,
    params: Dict(String, String),
  )
}

fn default_response() {
  response.new()
}

pub fn new(request: Request) {
  Context(
    request,
    default_response(),
    request.path
    |> path.from_string,
    dict.new(),
  )
}

pub fn set_path(ctx: Context, path: Path) -> Context {
  Context(..ctx, path: path)
}

pub fn set_status(ctx: Context, status: Int) -> Context {
  let http_resp.Response(status: _, headers: headers, body: body) = ctx.resp
  let resp = http_resp.Response(status: status, headers: headers, body: body)
  Context(..ctx, resp: resp)
}

pub fn text(ctx: Context, text: String) -> Response {
  let http_resp.Response(status: status, headers: headers, ..) = ctx.resp
  let body = mist.Bytes(bytes_builder.from_string(text))
  http_resp.Response(status: status, headers: headers, body: body)
}

pub fn error(ctx: Context, code: Int, message: String) -> Response {
  let body = mist.Bytes(bytes_builder.from_string(message))

  let ctx =
    ctx
    |> set_status(code)

  ctx.resp
  |> http_resp.set_body(body)
}

pub fn html(ctx: Context, path: String) -> Response {
  use data <- util.when_ok(
    simplifile.read(from: path),
    ctx
    //TODO: Respond with correct code
    |> error(404, "Failed to get html file: " <> path),
  )
  let body = mist.Bytes(bytes_builder.from_string(data))
  ctx.resp
  |> http_resp.set_body(body)
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
  let Context(request: req, resp: resp, params: params, ..) = ctx
  Context(
    ..ctx,
    request: req,
    resp: resp,
    params: dict.insert(params, key, value),
  )
}

pub fn add_params(ctx: Context, params: Dict(String, String)) -> Context {
  let Context(request: req, resp: resp, params: ctxparams, ..) = ctx
  Context(
    ..ctx,
    request: req,
    resp: resp,
    params: dict.merge(ctxparams, params),
  )
}

pub fn new_cookie(ctx: Context) -> Cookie {
  http_cookie.defaults(ctx.request.scheme)
  |> Cookie("", "")
}

pub fn set_cookie(ctx: Context, cookie: Cookie) -> Context {
  let resp =
    ctx.resp
    |> http_resp.set_cookie(cookie.name, cookie.value, cookie.attributes)

  Context(..ctx, resp: resp)
}

pub fn get_cookie(ctx: Context, name: String) -> Option(String) {
  ctx.request
  |> http_req.get_cookies
  |> list.find(fn(cookie) { cookie.0 == name })
  |> result.map(fn(cookie) { cookie.1 })
  |> option.from_result
}

pub fn set_header(ctx: Context, name: String, value: String) -> Context {
  let resp =
    ctx.resp
    |> http_resp.set_header(name, value)
  Context(..ctx, resp: resp)
}

pub fn get_header(ctx: Context, name: String) -> Option(String) {
  ctx.request
  |> http_req.get_header(name)
  |> option.from_result
}

pub fn get_query_param(ctx: Context, name: String) -> Option(String) {
  use query <- option.then(
    ctx.request
    |> http_req.get_query
    |> option.from_result,
  )
  query
  |> list.find(fn(query) {
    let #(qname, _) = query
    qname == name
  })
  |> result.map(fn(query) {
    let #(_, qval) = query
    qval
  })
  |> option.from_result
}

///Apply a callback onto a result object if it exists, returning data to send back to the client
///This allows route handlers to simplify the calls of various get functions such as get_parameter
///and replace the case expression with a use statement to reduce code.
pub fn then(result: Option(a), fun: fn(a) -> Response) -> Response {
  case result {
    Some(dat) -> {
      fun(dat)
    }
    None -> {
      let body = mist.Bytes(bytes_builder.from_string("Something went wrong!"))
      http_resp.new(404)
      |> http_resp.set_body(body)
    }
  }
}

pub type Decoder(a) =
  fn(dynamic.Dynamic) -> Result(a, List(dynamic.DecodeError))

pub type JsonDecoder(a) =
  fn(dynamic.Dynamic) -> Result(a, List(json.DecodeError))

pub type DecodeError {
  DecodeError(message: String)
}

pub fn convert_json_decode_error(err: json.DecodeError) -> DecodeError {
  let message = case err {
    json.UnexpectedEndOfInput -> "Unexpected end of input"
    json.UnexpectedByte(byte, pos) ->
      "Unexpected byte "
      <> byte
      <> " @ "
      <> int.to_string(pos)
    json.UnexpectedSequence(byte, pos) ->
      "Unexpected sequence "
      <> byte
      <> " @ "
      <> int.to_string(pos)
    json.UnexpectedFormat(errors) ->
      "Unexpected format: "
      <> string.join(
        errors
        |> list.map(fn(err) {
          "Expected "
          <> err.expected
          <> " but found "
          <> err.found
          <> " @ "
          <> string.join(err.path, ",")
        }),
        ",",
      )
  }
  DecodeError(message)
}

pub fn convert_decode_error(err: dynamic.DecodeError) -> DecodeError {
  let message =
    "Expected "
    <> err.expected
    <> " but found "
    <> err.found
    <> " @ "
    <> string.join(err.path, ",")
  DecodeError(message)
}

pub fn convert_decode_error_list(
  errors: List(dynamic.DecodeError),
) -> List(DecodeError) {
  errors
  |> list.map(fn(err) { convert_decode_error(err) })
}

pub fn bind(ctx: Context, decoder: Decoder(a)) -> Result(a, DecodeError) {
  ctx.request
  |> request.load_body
  |> result.map_error(fn(err) { DecodeError(err.message) })
  |> result.map(fn(req) {
    decoder(
      req.body
      |> dynamic.from,
    )
    |> result.map_error(convert_decode_error_list)
  })
  |> result.map(fn(res) {
    result.map_error(res, fn(errs) {
      errs
      |> list.map(fn(err) { err.message })
      |> string.join("\n")
      |> DecodeError
    })
  })
  |> result.flatten
}

pub fn bind_json(ctx: Context, decoder: Decoder(a)) -> Result(a, DecodeError) {
  ctx.request
  |> request.load_body
  |> result.map_error(fn(err) { DecodeError(err.message) })
  |> result.map(fn(req) {
    json.decode_bits(req.body, decoder)
    |> result.map_error(fn(err) { convert_json_decode_error(err) })
  })
  |> result.flatten
}
