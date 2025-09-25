///|
struct GameState {
  player : @system.Entity
  mut player_state : PlayerState
  mut direction : Direction2
  mut score : Int
  result_box : @sprite.Text
  score_box : @sprite.Text
  health_box : @sprite.Text
  volume_on : Bool
  mut health : Int
  mut hurt_timer : Double
  mut attack_hit_count : Int
  mut roll_count : Int
  mut roll_cooldown : Double
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
}

///|
enum Direction2 {
  Left
  Right
}

///|
const ATTACK_V : Double = 180.0

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
  game_state.score_box.content = "Score: " + game_state.score.to_string()
}

///|
fn update_health_display() -> Unit {
  game_state.health_box.content = "HP: " + game_state.health.to_string()
}
