#[macro_use]
extern crate rocket;

#[get("/")]
fn index() -> &'static str {
    "Hello, world! From Rocket! 🚀😄🚀\n"
}

#[launch]
fn rocket() -> _ {
    rocket::build().mount("/", routes![index])
}
