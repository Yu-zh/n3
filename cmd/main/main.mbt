///|
/// n3 - A Ninja build system implementation in MoonBit
async fn main {
  let code = @n3.run(@env.args())
  guard code is 0
}
