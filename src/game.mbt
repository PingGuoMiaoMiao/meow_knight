///|
enum Scene {
  Level1     // 第一关
  Level2     // 第二关（击败Older后）
  // 可以添加更多关卡
} derive(Eq, Show)

///|
struct GameState {
  player : @system.Entity
  mut player_state : PlayerState
  mut direction : Direction2
  mut score : Int
  result_box : @sprite.Text
  score_box : @sprite.Text
  health_box : @sprite.Text
  volume_on : Bool  // 改回不可变
  mut health : Int
  mut hurt_timer : Double
  mut attack_hit_count : Int
  mut roll_count : Int
  mut roll_cooldown : Double
  mut last_down_press_time : Double  // 记录上次按下蹲键的时间
  mut current_scene : Scene
  mut scene_transition : Bool  // 是否正在场景切换
  mut scene_transition_timer : Double  // 场景切换计时器
}

///|
let game_state : GameState = {
  player: @system.Entity::new(),
  player_state: PlayerState::Idle,
  score: 0,
  result_box: @sprite.Text::new("", font="24px ThaleahFat"),
  score_box: @sprite.Text::new(
    "Score: 0",
    font="20x ThaleahFat",
    color="#ffffff",
  ),
  health_box: @sprite.Text::new(
    "Health: 3",
    font="20px ThaleahFat",
    color="#ffffff",
  ),
  direction: Direction2::Right,
  volume_on: true,
  health: 3,
  hurt_timer: 0.0,
  attack_hit_count: 0,
  roll_count: 0,
  roll_cooldown: 0.0,
  last_down_press_time: -999.0,  // 初始化为很久以前
  current_scene: Scene::Level1,  // 从第一关开始
  scene_transition: false,       // 初始不在切换状态
  scene_transition_timer: 0.0,   // 场景切换计时器初始值
}

///|
enum Direction2 {
  Left
  Right
}

///|
const ATTACK_V : Double = 180.0

///|
const DOUBLE_TAP_WINDOW : Double = 20.0  // 双击时间窗口（20帧 ≈ 0.33秒）

///|
fn hurt_player() -> Unit {
  if game_state.hurt_timer <= 0.0 {
    let back_vel = match game_state.direction {
      Left => @math.Vec2D(ATTACK_V, 0.0)
      Right => @math.Vec2D(-ATTACK_V, 0.0)
    }
    @velocity.velocities[game_state.player] = back_vel
    game_state.player_state = PlayerState::Hit
    game_state.health -= 1
    update_health_display()
    game_state.hurt_timer = 60.0
    if game_state.volume_on {
      @audio.play_audio("sounds/hurt.wav")
    }
  }
}

///|
fn set_score(score : Int) -> Unit {
  game_state.score = score
  update_score(score)  // 使用新的UI更新函数
}

///|
fn update_health_display() -> Unit {
  update_health(game_state.health)  // 使用新的UI更新函数
}
