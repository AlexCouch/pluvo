import gleam/http/cookie.{type Attributes, Attributes}
import gleam/option.{Some}

pub type Cookie{
    Cookie(attributes: Attributes, name: String, value: String)
}

pub fn set(cookie: Cookie, name: String, value: String) -> Cookie{
    Cookie(..cookie, name: name, value: value)
}

pub fn expires(cookie: Cookie, max_age: Int) -> Cookie{
    let attrs = Attributes(..cookie.attributes, max_age: Some(max_age))
    Cookie(..cookie, attributes: attrs)
}
