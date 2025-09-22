///|
struct GameState {
  player : @system.Entity
  mut player_state : PlayerState
  mut direction : Direction2
  mut score : Int
  result_box : @sprite.Text
  score_box : @sprite.Text
  health_box : @sprite.Text
  mut volume_on : Bool
  mut health : Int
  mut hurt_timer : Double
}

let game_state : GameState = {
  player: @system.Entity::new(),
  player_state: PlayerState::Idle,
  score : 0,
  result_box: @sprite.Text::new("", font="24px ThaleahFat",),
  score_box: @sprite.Text::new("Score: 0", font="20x ThaleahFat",color="#ffffff",),
  health_box: @sprite.Text::new("Health: 3", font="20px ThaleahFat",color="#ffffff",),
  direction: Direction2::Right,
  volume_on: true,
  health: 3,
  hurt_timer: 0.0,
}

enum Direction2 {
  Left
  Right
}