# gleamtry

[![Package Version](https://img.shields.io/hexpm/v/gleamtry)](https://hex.pm/packages/gleamtry)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleamtry/)

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation
This is not yet usable as a dependency, however, cloning the project and running the
above commands will help you get started

## Example
In your main function, you must create a new pluvo object. This will store things like your 
routes. Piping the object into `pluvo.router()` will allow you to register new routes.
```gleam 
import routes 
import pluvo

pub fn main(){
    let pluv = pluvo.new()

    let routes = pluvo.router
    |> router.get("/home", home.handler)

    pluv 
    |> pluvo.add_router(routes)
    |> pluvo.start(3000)
}
```

## Project Structure
Your project should be structured like this 
```
root -
    |- src
        |- routes 
            |- ...
        |- main.gleam
```
In your src directory, create a folder called `routes`. Each file in this directory 
should be for a single route. 

## Routes 
A route is a file which has either a `view` or a `handler`. Naming convention is 
not enforced, however, you can think of it like this:

A `view` simply returns a view or an html file.
A `handler` simply does something such as return an API result, fetch some data from a database, etc.

```gleam 
//routes/index.gleam
pub fn view(ctx: Context) -> Response(ResponseData){
    ctx 
    |> context.html("/static/views/index.html")
}

pub fn handle(ctx: Context) -> Respone(ResponseData){
    //Get data from database
    //Convert data to JSON string
    ctx 
    |> context.text(json_data)
}
```

## Groups
Groups are useful for giving a group of routes a shared set of properties, such as a prefix, authentication, middleware, etc.

```gleam 
import pluvo
import pluvo/router 
import pluvo/group
import routes/admin/dashboard

pub fn main(){
    let pluv = pluvo.new()

    let routes = pluvo.router
    |> router.get("/home", home.handler)

    let admin = pluvo.group("/admin")
    |> group.get("/dashboard", dashboard.handler)

    pluv 
    |> pluvo.add_router(routes)
    |> plugo.add_group(admin)
    |> pluvo.start(3000)
}
```
