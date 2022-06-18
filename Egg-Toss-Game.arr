use context essentials2021
import reactors as R
import image as I

### TYPES ###

data PlatformLevel:
  | top
  | middle
  | bottom
end

data GameStatus:
  | ongoing
  | transitioning(ticks-left :: Number)
  | game-over
end

type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
  dy :: Number
}

type Egg = {
  x :: Number,
  y :: Number,
  dx :: Number,
  dy :: Number,
  ay :: Number,
  is-airborne :: Boolean,
}

type State = {
  egg :: Egg,
  top-platform :: Platform,
  middle-platform :: Platform,
  bottom-platform :: Platform,
  current-platform :: PlatformLevel,
  lives :: Number,
  game-status :: GameStatus,
  other-platforms :: List<Platform>,
  score :: Number,
  old-top-dx :: Number
}

### CONSTANTS ###

FPS = 30

SCREEN-WIDTH = 300
SCREEN-HEIGHT = 500
SCREEN-COLOR = "lavender-blush"

PLATFORM-WIDTH = 65
PLATFORM-HEIGHT = 10
PLATFORM-COLOR = "saddle-brown"
PLATFORM-BASE-SPEED = 1

EGG-RADIUS = 15
EGG-COLOR = "navajo-white"
EGG-AY = 1

LIVES-TEXT-COLOR = "olive"
LIVES-TEXT-SIZE = 16
LIVES-TEXT-X = 250
LIVES-TEXT-Y = 25

SCORE-TEXT-COLOR = "olive"
SCORE-TEXT-SIZE = 30
SCORE-TEXT-X = SCREEN-WIDTH / 2
SCORE-TEXT-Y = 50

GAMEOVER-TEXT-COLOR = "red"
GAMEOVER-TEXT-SIZE = 36
GAMEOVER-TEXT-X = SCREEN-WIDTH / 2
GAMEOVER-TEXT-Y = SCREEN-HEIGHT / 2

JUMP-VELOCITY = -19

TRANSITION-TICKS = (3 / 2) * FPS

SCROLL-SPEED = (SCREEN-HEIGHT / 2) / TRANSITION-TICKS

### RANDOMIZING ###

fun randomize-platform-speed():
  parity = num-random(2)
  if parity == 0:
    0 - (PLATFORM-BASE-SPEED + (num-random(12) / 2))
  else:
    PLATFORM-BASE-SPEED + (num-random(12) / 2)
  end
end

fun randomize-platform-x():
  PLATFORM-WIDTH + num-random(SCREEN-WIDTH - (PLATFORM-WIDTH * 2))
end

fun generate-platform(y :: Number) -> Platform:
  { x: randomize-platform-x(),
    y: y,
    dx: 0,
    dy: SCROLL-SPEED
  }
end

### INITIAL ###

INITIAL-STATE = {
  egg: {
      x: SCREEN-WIDTH / 2,
      y: ((SCREEN-HEIGHT * (3 / 4)) - EGG-RADIUS) - (PLATFORM-HEIGHT / 2),
      dx: 0,
      dy: 0,
      ay: 0,
      is-airborne: false
    },
  top-platform: {
      x: SCREEN-WIDTH / 2,
      y: SCREEN-HEIGHT / 4,
      dx: randomize-platform-speed(),
      dy: 0
    },
  middle-platform: {
      x: SCREEN-WIDTH / 2,
      y: SCREEN-HEIGHT / 2,
      dx: randomize-platform-speed(),
      dy: 0
    },
  bottom-platform: {
      x: SCREEN-WIDTH / 2,
      y: SCREEN-HEIGHT * (3 / 4),
      dx: randomize-platform-speed(),
      dy: 0
    },
  current-platform: bottom,
  lives: 12,
  game-status: ongoing,
  other-platforms: empty,
  score: 0,
  old-top-dx: 0
}

### DRAWING ###

fun draw-platform(platform :: Platform, acc :: Image) -> Image:
    img = rectangle(PLATFORM-WIDTH, PLATFORM-HEIGHT, "solid", PLATFORM-COLOR)

    place-image(img, platform.x, platform.y, acc)
end

fun draw-platforms(state :: State, acc :: Image) -> Image:
  acc
    ^ draw-platform(state.top-platform, _)
    ^ draw-platform(state.middle-platform, _)
    ^ draw-platform(state.bottom-platform, _)
end

fun draw-other-platforms(state :: State, acc :: Image) -> Image:
  if state.other-platforms.length() > 0:
    state.other-platforms.foldr(draw-platform, acc)
  else:
    acc
  end
end

fun draw-egg(state :: State, acc :: Image) -> Image:
  egg = circle(EGG-RADIUS, "solid", EGG-COLOR)
  
  place-image(egg, state.egg.x, state.egg.y, acc)
end

fun draw-lives-text(state :: State, acc :: Image) -> Image:
  txt = text("Lives: " + num-to-string(state.lives), LIVES-TEXT-SIZE, LIVES-TEXT-COLOR)
  
  place-image(txt, LIVES-TEXT-X, LIVES-TEXT-Y, acc)
end

fun draw-score-text(state :: State, acc :: Image) -> Image:
  txt = text(num-to-string(state.score), SCORE-TEXT-SIZE, SCORE-TEXT-COLOR)
  
  place-image(txt, SCORE-TEXT-X, SCORE-TEXT-Y, acc)
end

fun draw-gameover-text(acc :: Image) -> Image:
  txt = text("GAME OVER", GAMEOVER-TEXT-SIZE, GAMEOVER-TEXT-COLOR)
  
  place-image(txt, GAMEOVER-TEXT-X, GAMEOVER-TEXT-Y, acc)
end

fun draw-handler(state :: State) -> Image:
  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, SCREEN-COLOR)
  
  canvas-with-game = canvas
    ^ draw-lives-text(state, _)
    ^ draw-score-text(state, _)
    ^ draw-platforms(state, _)
    ^ draw-other-platforms(state, _)
    ^ draw-egg(state, _)
  if state.game-status == game-over:
    canvas-with-game
      ^ draw-gameover-text(_)
  else:
    canvas-with-game
  end
  
end



### TICKS ###

fun update-egg-position(state :: State) -> State:
  egg = state.egg
  
  state.{egg: egg.{x: egg.x + egg.dx, y: egg.y + egg.dy}}
end

fun update-egg-vertical-velocity(state :: State) -> State:
  egg = state.egg
 
  state.{egg: egg.{dy: egg.dy + egg.ay}}
end

fun update-egg-horizontal-velocity(state :: State) -> State:
  egg = state.egg
  if egg.is-airborne == false:
    cases (PlatformLevel) state.current-platform:
      | top => state.{egg: egg.{dx: state.top-platform.dx}}
      | middle => state.{egg: egg.{dx: state.middle-platform.dx}}
      | bottom => state.{egg: egg.{dx: state.bottom-platform.dx}}
    end
  else:
    state.{egg: egg.{dx: 0}}
  end
end

fun update-egg-acceleration(state :: State) -> State:
  egg = state.egg
  if egg.is-airborne == true:
    state.{egg: egg.{ay: EGG-AY}}
  else:
    state.{egg: egg.{ay: 0}}
  end
end

fun update-platforms-position(state :: State) -> State:
  fun helper(platform :: Platform) -> Platform:
    platform.{x: platform.x + platform.dx, y: platform.y + platform.dy}
  end
  
  cases (GameStatus) state.game-status:
    | ongoing => 
      state.{
        top-platform: helper(state.top-platform), 
        middle-platform: helper(state.middle-platform), 
        bottom-platform: helper(state.bottom-platform)
      }
    | transitioning(_) => state.{
        top-platform: helper(state.top-platform), 
        middle-platform: helper(state.middle-platform), 
        bottom-platform: helper(state.bottom-platform),
        other-platforms: state.other-platforms.map(helper)
      }
  end
end

fun update-platforms-collision(state :: State) -> State:
  fun helper(platform :: Platform) -> Platform:
    is-colliding = ((platform.x - (PLATFORM-WIDTH / 2)) < 0) or ((platform.x + (PLATFORM-WIDTH / 2)) > SCREEN-WIDTH)
    if is-colliding:
      platform.{dx: 0 - platform.dx}
    else:
      platform
    end
  end
  
  state.{top-platform: helper(state.top-platform), middle-platform: helper(state.middle-platform), bottom-platform: helper(state.bottom-platform)}
end

fun update-egg-offscreen(state :: State) -> State:
  egg = state.egg
  
  if egg.y >= (SCREEN-HEIGHT + EGG-RADIUS):
    if state.lives == 1:
      state.{lives: state.lives - 1}
    else:
      respawn-egg(state.{lives: state.lives - 1})
    end
  else:
    state
  end
end

fun respawn-egg(state :: State) -> State:
  # Respawn egg in middle of current platform
  egg = state.egg
  current-platform = cases (PlatformLevel) state.current-platform:
    | top => state.top-platform
    | middle => state.middle-platform
    | bottom => state.bottom-platform
  end

  new-egg = egg.{
    x: current-platform.x,
    y: ((current-platform.y) - EGG-RADIUS) - (PLATFORM-HEIGHT / 2),
    dx: current-platform.dx,
    dy: 0,
    ay: 0,
    is-airborne: false
  }
  state.{egg: new-egg}
end

fun update-egg-collision(state :: State) -> State:
  cases (GameStatus) state.game-status:
    | transitioning(_) => state
    | game-over => state
    | ongoing => 
      bottom-egg-x = state.egg.x
      bottom-egg-y = state.egg.y + EGG-RADIUS
      if state.egg.dy >= 0:
        cases (PlatformLevel) state.current-platform:
          | bottom => 
            within-middle-platform = (bottom-egg-x <= (state.middle-platform.x + (PLATFORM-WIDTH / 2))) and (bottom-egg-x >= (state.middle-platform.x - (PLATFORM-WIDTH / 2)))
            same-height-as-middle = (bottom-egg-y <= (state.middle-platform.y + (PLATFORM-HEIGHT / 2))) and (bottom-egg-y >= ((state.middle-platform.y + (PLATFORM-HEIGHT / 2)) - (state.egg.dy + state.egg.ay)))
            if within-middle-platform and same-height-as-middle:
              state.{egg: state.egg.{ay: 0, dy: 0, y: (SCREEN-HEIGHT / 2) - (PLATFORM-HEIGHT / 2) - EGG-RADIUS, is-airborne: false}, current-platform: middle, score: state.score + 1}
            else:
              state
            end

          | middle => 
            within-platform-top = (bottom-egg-x < (state.top-platform.x + (PLATFORM-WIDTH / 2))) and (bottom-egg-x > (state.top-platform.x - (PLATFORM-WIDTH / 2)))
            same-height-as-top = (bottom-egg-y <= (state.top-platform.y + (PLATFORM-HEIGHT / 2))) and (bottom-egg-y >= ((state.top-platform.y + (PLATFORM-HEIGHT / 2)) - (state.egg.dy + state.egg.ay)))
            if within-platform-top and same-height-as-top:
              state.{egg: state.egg.{ay: 0, dy: 0, y: (SCREEN-HEIGHT / 4) - (PLATFORM-HEIGHT / 2) - EGG-RADIUS, is-airborne: false}, current-platform: top, score: state.score + 1}
            else:
              state
            end
          | top =>
            state.{game-status: transitioning(TRANSITION-TICKS), 
              old-top-dx: state.top-platform.dx
            }
        end

      else:
        state
      end
  end
end



fun update-transition(state :: State) -> State:
  game-status = state.game-status
  
  cases (GameStatus) game-status:
    | ongoing => state
    | gameover => state
    | transitioning(ticks-left) => 
      if ticks-left == TRANSITION-TICKS:
        new-middle-platform = generate-platform(0)
        new-top-platform = generate-platform(0 - (SCREEN-HEIGHT / 4))
        
        other-platforms = [list: new-middle-platform, new-top-platform]
        
        state.{egg: state.egg.{dx: 0, dy: SCROLL-SPEED}, 
          top-platform: state.top-platform.{dx: 0, dy: SCROLL-SPEED},
          middle-platform: state.middle-platform.{dx: 0, dy: SCROLL-SPEED},
          bottom-platform: state.bottom-platform.{dx: 0, dy: SCROLL-SPEED},
          game-status: transitioning(ticks-left - 1),
          other-platforms: other-platforms
        }
      else if ticks-left == 0:
        new-middle-platform = state.other-platforms.get(0).{dy: 0, dx: randomize-platform-speed()}
        new-top-platform = state.other-platforms.get(1).{dy: 0, dx: randomize-platform-speed()}
        new-bottom-platform = state.top-platform.{dy: 0, dx: state.old-top-dx}
        
        
        state.{
          top-platform: new-top-platform,
          middle-platform: new-middle-platform,
          bottom-platform: new-bottom-platform,
          egg: state.egg.{dy: 0, dx: new-bottom-platform.dx},
          game-status: ongoing,
          current-platform: bottom,
          other-platforms: empty
        }
      else:
        state.{game-status: transitioning(ticks-left - 1)}
      end
  end
end

fun update-gameover(state :: State) -> State:
  if state.lives == 0:
    state.{game-status: game-over}
  else:
    state
  end
end

fun tick-handler(state :: State) -> State:
  if state.game-status == game-over:
    state
  else:
    state
      ^ update-egg-acceleration(_)
      ^ update-egg-vertical-velocity(_)
      ^ update-egg-horizontal-velocity(_)
      ^ update-egg-position(_)
      ^ update-platforms-position(_)
      ^ update-transition(_)
      ^ update-egg-collision(_)
      ^ update-egg-offscreen(_)
      ^ update-platforms-collision(_)
      ^ update-gameover(_)
  end
end


### KEYS ###

fun key-handler(state :: State, key :: String) -> State:
  cases (GameStatus) state.game-status:
    | ongoing => 
      if (key == " ") and not(state.current-platform == top):
        if state.egg.is-airborne:
          state
        else:
          new-egg = state.egg.{dy: JUMP-VELOCITY, is-airborne: true}
          state.{egg: new-egg}
        end
      else:
        state
      end
    | transitioning(_) => 
      state
    | game-over => 
      if key == " ":
        INITIAL-STATE
      else:
        state
      end
  end
end



### MAIN ###

game = reactor:
  init: INITIAL-STATE,
  seconds-per-tick: 1 / FPS,
  on-tick: tick-handler,
  on-key: key-handler,
  to-draw: draw-handler
end 

R.interact(game)













