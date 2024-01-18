import gleam/option.{type Option, None, Some}

pub fn whennot(on condition: Bool, then default: a, orelse fun: fn() -> a) -> a {
  case condition {
    True -> fun()
    False -> default
  }
}

pub fn when(on condition: Bool, then default: a, orelse fun: fn() -> a) -> a {
  case condition {
    False -> fun()
    True -> default
  }
}

pub fn when_some(
  with option: Option(a),
  then fun: fn(a) -> b,
  orelse default: b,
) -> b {
  case option {
    Some(data) -> fun(data)
    None -> default
  }
}

pub fn when_none(
  with condition: Option(a),
  then default: b,
  orelse fun: fn(a) -> b,
) -> b {
  case condition {
    Some(data) -> fun(data)
    None -> default
  }
}

pub fn when_ok(
  with option: Result(a, b),
  then default: c,
  orelse fun: fn(a) -> c,
) -> c {
  case option {
    Ok(data) -> fun(data)
    Error(_) -> default
  }
}

pub fn when_err(
  with condition: Result(a, b),
  then default: c,
  orelse fun: fn(b) -> c,
) -> c {
  case condition {
    Ok(_) -> default
    Error(err) -> fun(err)
  }
}
