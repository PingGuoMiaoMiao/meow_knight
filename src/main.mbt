///|
const ZOOM : Double = 2.0

///|
fn main {
  @system.App::new()
  .with_canvas_width(480.0)
  .with_canvas_height(320.0)
  .with_image_smooth(false)
  .with_fps(120)
  .with_zoom(ZOOM)
  .add_plugin(@plugins.default_plugin)
  .add_system(game_start, schedule=Startup)
  .add_system(player_state_system)
  .add_system(player_collision_system)
  .run()
}

///|
fn game_start(_delta : Double) -> Unit {
  generate_map()
}
