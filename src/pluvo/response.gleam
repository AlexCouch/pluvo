import gleam/http/response
import mist.{type ResponseData, Bytes}
import gleam/bytes_builder
import gleam/bit_array
import gleam/option.{type Option, None}

pub type Response =
  response.Response(ResponseData)

pub fn new() -> Response {
  response.new(200)
  |> response.set_body(mist.Bytes(bytes_builder.new()))
}

pub fn get_body(resp: Response) -> Option(String) {
  case resp.body {
    Bytes(data) -> {
      data
      |> bytes_builder.to_bit_array
      |> bit_array.to_string
      |> option.from_result
    }
    //TODO: Maybe later we should add handling for the other data types
    _ -> None
  }
}
