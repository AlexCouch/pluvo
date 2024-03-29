import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/list
import gleam/string_builder
import pluvo/util

pub type Path {
  Path(parts: List(PathPart), length: Int)
}

pub type PathPart {
  Segment(seg: String)
  Parameter(name: String)
}

pub fn new(parts: List(PathPart)) -> Path {
  Path(parts: parts, length: list.length(parts))
}

pub fn default_if_empty(parts: List(String)) -> List(String) {
  case list.length(parts) {
    0 -> ["/"]
    _ -> parts
  }
}

pub fn reduce_dups(parts: List(String)) -> List(String) {
  parts
  |> list.drop_while(satisfying: fn(part) { string.is_empty(part) })
  |> default_if_empty
}

pub fn to_part(part: String) -> PathPart {
  use <- util.whennot(string.starts_with(part, ":"), Segment(part))
  Parameter(string.drop_left(part, 1))
}

pub fn create_parts(parts: List(String)) -> List(PathPart) {
  parts
  |> reduce_dups
  |> default_if_empty
  |> list.map(to_part)
}

pub fn from_string(path: String) -> Path {
  path
  |> string.split("/")
  |> create_parts
  |> new
}

pub fn to_string(path: Path) -> String {
  path.parts
  |> list.map(fn(part) {
    case part {
      Segment(seg) -> string_builder.from_string(seg)
      Parameter(param) -> string_builder.from_string(param)
    }
  })
  |> string_builder.join("/")
  |> string_builder.to_string
}

pub fn last(path: Path) -> Option(PathPart) {
  let Path(parts, _) = path
  list.last(parts)
  |> option.from_result
}

pub fn is_parameter(path: Path) -> Bool {
  case
    path
    |> last
  {
    Some(Parameter(_)) -> True
    _ -> False
  }
}

pub fn has_parameter(path: Path, param: String) -> Bool {
  case
    path
    |> last
  {
    Some(Parameter(pname)) -> {
      use <- util.when(pname == param, True)
      False
    }
    _ -> False
  }
}

pub fn is_parent(path: Path, other: Path) -> Bool {
  case get_parent(path) {
    Some(parent) -> {
      use <- util.when(compare(parent, other), True)
      is_parent(parent, other)
    }
    None -> False
  }
}

pub fn shares_parent(path: Path, other: Path) -> Bool {
  case get_parent(path), get_parent(other) {
    Some(left), Some(right) -> compare(left, right)
    _, _ -> False
  }
}

pub fn compare(path: Path, other: Path) -> Bool {
  //We need an additional check for length
  use <- util.whennot(on: path.length == other.length, then: False)
  case path, other {
    //Compare the current segments
    Path([head, ..tail], _), Path([other_head, ..other_tail], _) -> {
      //We need to check if the left head is a parameter or not
      //because if it is a parameter, then we need to treat the 
      //right head as a parameter
      case head, other_head {
        //If it's a param, just skip over it
        Parameter(_), _ -> compare(new(tail), new(other_tail))
        //Otherwise, if it's two segments being compared, then 
        //compare the inner segments
        Segment(seg), Segment(other_seg) -> {
          use <- util.whennot(seg == other_seg, False)
          compare(new(tail), new(other_tail))
        }
        _, _ -> False
      }
    }
    //If we have reached the end of both paths, then return True
    //This means we have two paths with the same lengths
    //We ignore the lengths because we infer them from the empty list pattern
    Path([], _), Path([], _) -> True
    //Otherwise, return False
    //This most likely means that the lengths of the two paths are different
    _, _ -> False
  }
}

pub fn get_all_parents(path: Path) -> List(Path) {
  get_parent(path)
  |> option.map(fn(parent) { [path, ..get_all_parents(parent)] })
  |> option.unwrap([])
}

pub fn get_parent(path: Path) -> Option(Path) {
  let Path(parts, length) = path
  case parts {
    [] -> None
    _ -> {
      let parent = list.take(parts, length - 1)
      Some(Path(parent, length - 1))
    }
  }
}
