module Internal.Snackbar.Model exposing
    ( Contents
    , defaultModel
    , Model
    , Msg(..)
    , State(..)
    , Transition(..)
    )

import Time exposing (Time)
import Html exposing (Html)


type alias Model m =
    { queue : List (Contents m)
    , state : State m
    , seq : Int
    }


type alias Contents m =
    { message : String
    , action : Maybe String
    , timeout : Time
    , fade : Time
    , multiline : Bool
    , actionOnBottom : Bool
    , dismissOnAction : Bool
    , onDismiss : Maybe m
    , fab : Maybe (Html m)
    }


type State m
    = Inert
    | Active (Contents m)
    | Fading (Contents m)


defaultModel : Model m
defaultModel =
    { queue = []
    , state = Inert
    , seq = -1
    }


type Msg m
    = Move Int Transition
    | Dismiss Bool (Maybe m)


type Transition
    = Timeout
    | Clicked
