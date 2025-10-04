///|
const ZOOM : Double = 2.0

const World_Width : Double = 500.0

const World_Height : Double = 600.0

///|
fn main {
  @system.App::new()
  .with_canvas_width(World_Width)
  .with_canvas_height(World_Height)
  .with_image_smooth(false)
  .with_fps(120)
  .with_zoom(ZOOM)
  .add_plugin(@plugins.default_plugin)
  .add_system(game_start, schedule=Startup)
  .add_system(dialogue_input_system)
  .add_system(player_state_system)
  .add_system(player_collision_system)
  .add_system(skeleton_ai_system)
  .add_system(older_ai_system)
  .add_system(mushroom_ai_system)
  .add_system(silme_ai_system)
  .add_system(cat_ai_system)
  .add_system(sprite_ai_system)
  .run()
}

///|
fn game_start(_delta : Double) -> Unit {
  generate_map()
  
  // 添加简化的UI元素
  add_score_box()
  add_health_box()
  add_volume_button()
}

///| 对话框输入系统 - 监听空格键切换对话或关闭对话框
fn dialogue_input_system(_delta : Double) -> Unit {
  if is_dialogue_showing() {
    // 检查空格键是否被按下
    if @inputs.is_just_pressed(@inputs.Space) {
      // 如果有对话队列，显示下一段
      if has_dialogue_queue() {
        show_next_dialogue()
        println("➡️ 显示下一段对话")
      } else {
        // 没有队列，直接关闭
        clear_dialogue()
        println("🚪 对话框已关闭（空格键）")
      }
    }
  }
}
