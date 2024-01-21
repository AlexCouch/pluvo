import gleam/http/request
import mist.{type Connection}
import gleam/option.{type Option, None, Some}
import gleam/int
import gleam/bit_array
import gleam/result

pub type Request =
  request.Request(Connection)

//Temporary work around until the body is more cleanly implemented for binding to model data via json (or anything else)
pub fn get_body(req: Request) -> Option(String) {
  use contlen <- option.then(
    req
    |> request.get_header("content-length")
    |> option.from_result,
  )
  use contlen <- option.then(
    contlen
    |> int.parse
    |> option.from_result,
  )

  let body =
    req
    |> mist.read_body(contlen)
  case body {
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
