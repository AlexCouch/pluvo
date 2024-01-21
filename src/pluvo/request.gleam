import gleam/http/request
import mist.{type Connection, type ReadError}
import gleam/option.{type Option, None, Some}
import gleam/int
import gleam/bit_array
import gleam/result

pub type Request =
  request.Request(Connection)

pub type RequestError {
  RequestError(message: String)
}

pub fn load_body(
  req: Request,
) -> Result(request.Request(BitArray), RequestError) {
  use contlen <- result.then(
    req
    |> request.get_header("content-length")
    |> result.replace_error(RequestError("Failed to get content-length header")),
  )
  use contlen <- result.then(
    contlen
    |> int.parse
    |> result.replace_error(RequestError("Failed to parse content-length header",
    )),
  )

  req
  |> mist.read_body(contlen)
  |> result.replace_error(RequestError("Failed to read body of request"))
}

//Temporary work around until the body is more cleanly implemented for binding to model data via json (or anything else)
pub fn get_body(req: Request) -> Option(String) {
  case load_body(req) {
    Ok(req) -> {
      let req =
        req
        |> request.map(fn(data) {
          data
          |> bit_array.to_string
          |> result.unwrap("")
        })
      Some(req.body)
    }
    //It's okay, we are not concerned about whether we *could* read it or not
    // we just want the data if it exists or not
    Error(_) -> None
  }
}
