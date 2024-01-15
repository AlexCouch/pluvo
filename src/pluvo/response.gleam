import gleam/http/response
import mist.{type ResponseData}

pub type Response = response.Response(ResponseData)
