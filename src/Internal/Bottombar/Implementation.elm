module Internal.Bottombar.Implementation exposing
    ( Property
    , actionItem
    , alignEnd
    , alignStart
    , collapsed
    , dense
    , denseFixedAdjust
    , fixed
    , fixedAdjust
    , hasActionItem
    , icon
    , navigationIcon
    , prominent
    , prominentFixedAdjust
    , react
    , section
    , short
    , title
    , view
    )

import DOM
import Html exposing (Html, text)
import Internal.Bottombar.Model exposing (Config, Model, Msg(..), defaultConfig, defaultModel)
import Internal.Component as Component exposing (Index, Indexed)
import Internal.GlobalEvents as GlobalEvents
import Internal.Icon.Implementation as Icon
import Internal.Msg
import Internal.Options as Options exposing (cs, css, nop, styled, when)
import Json.Decode as Json exposing (Decoder)


cssClasses :
    { dense : String
    , fixed : String
    , scrolled : String
    , prominent : String
    , short : String
    , collapsed : String
    }
cssClasses =
    { dense = "mdc-top-app-bar--dense"
    , fixed = "mdc-bottom-app-bar--fixed"
    , scrolled = "mdc-top-app-bar--fixed-scrolled"
    , prominent = "mdc-top-app-bar--prominent"
    , short = "mdc-top-app-bar--short"
    , collapsed = "mdc-top-app-bar--short-collapsed"
    }


update : Msg -> Model -> ( Model, Cmd m )
update msg model =
    case msg of
        Init { scrollPosition, topAppBarHeight } ->
            ( topAppBarScrollHandler scrollPosition
                { model
                    | lastScrollPosition = Just scrollPosition
                    , topAppBarHeight = Just topAppBarHeight
                }
            , Cmd.none
            )

        Scroll { scrollPosition } ->
            ( topAppBarScrollHandler scrollPosition model, Cmd.none )

        Resize { scrollPosition, topAppBarHeight } ->
            -- TODO: upstream implements resize trottling to 10 p/s.
            let
                currentHeight =
                    topAppBarHeight

                currentAppBarOffsetTop =
                    model.currentAppBarOffsetTop - (topAppBarHeight - currentHeight)

                updatedModel =
                    if Just topAppBarHeight /= model.topAppBarHeight then
                        { model
                            | wasDocked = False
                            , currentAppBarOffsetTop = currentAppBarOffsetTop
                            , topAppBarHeight = Just currentHeight
                        }

                    else
                        model
            in
            ( topAppBarScrollHandler scrollPosition updatedModel, Cmd.none )


topAppBarScrollHandler : Float -> Model -> Model
topAppBarScrollHandler scrollPosition model =
    Maybe.map2
        (\topAppBarHeight lastScrollPosition ->
            ( topAppBarHeight, lastScrollPosition )
        )
        model.topAppBarHeight
        model.lastScrollPosition
        |> Maybe.map
            (\( topAppBarHeight, lastScrollPosition ) ->
                let
                    currentScrollPosition =
                        max scrollPosition 0

                    diff =
                        currentScrollPosition - lastScrollPosition

                    currentAppBarOffsetTop =
                        model.currentAppBarOffsetTop - diff

                    updatedAppBarOffsetTop =
                        if not isCurrentlyBeingResized then
                            if currentAppBarOffsetTop > 0 then
                                0

                            else if abs currentAppBarOffsetTop > topAppBarHeight then
                                -topAppBarHeight

                            else
                                currentAppBarOffsetTop

                        else
                            model.currentAppBarOffsetTop

                    isCurrentlyBeingResized =
                        False

                    -- TODO: resize throttling
                    updatedModel =
                        { model
                            | lastScrollPosition = Just currentScrollPosition
                            , currentAppBarOffsetTop = updatedAppBarOffsetTop
                        }
                in
                Maybe.withDefault updatedModel (moveBottombar updatedModel)
            )
        |> Maybe.andThen moveBottombar
        |> Maybe.withDefault model


getViewportScrollY : Decoder Float
getViewportScrollY =
    DOM.target <|
        Json.at [ "ownerDocument", "defaultView", "scrollY" ] Json.float


getAppBarHeight : Decoder Float
getAppBarHeight =
    Json.at [ "target", "clientHeight" ] Json.float


checkForUpdate : Model -> Maybe ( Model, Bool )
checkForUpdate model =
    model.topAppBarHeight
        |> Maybe.map
            (\topAppBarHeight ->
                let
                    offscreenBoundaryTop =
                        -topAppBarHeight

                    hasAnyPixelsOffscreen =
                        model.currentAppBarOffsetTop < 0

                    hasAnyPixelsOnscreen =
                        model.currentAppBarOffsetTop > offscreenBoundaryTop

                    partiallyShowing =
                        hasAnyPixelsOffscreen && hasAnyPixelsOnscreen
                in
                if partiallyShowing then
                    ( { model | wasDocked = False }, True )

                else if not model.wasDocked then
                    ( { model | wasDocked = True }, True )

                else if model.isDockedShowing /= hasAnyPixelsOnscreen then
                    ( { model | isDockedShowing = hasAnyPixelsOnscreen }, True )

                else
                    ( model, False )
            )


moveBottombar : Model -> Maybe Model
moveBottombar model =
    checkForUpdate model
        |> Maybe.andThen
            (\( updatedModel, partiallyShowing ) ->
                if partiallyShowing then
                    updatedModel.topAppBarHeight
                        |> Maybe.map
                            (\topAppBarHeight ->
                                let
                                    styleTop =
                                        let
                                            maxBottombarHeight =
                                                128
                                        in
                                        if abs updatedModel.currentAppBarOffsetTop > topAppBarHeight then
                                            -maxBottombarHeight

                                        else
                                            updatedModel.currentAppBarOffsetTop
                                in
                                { updatedModel | styleTop = Just styleTop }
                            )

                else
                    Just updatedModel
            )



-- VIEW


bottombar : (Msg -> m) -> Model -> List (Property m) -> List (Html m) -> Html m
bottombar lift model options sections =
    let
        ({ config } as summary) =
            Options.collect defaultConfig options

        lastScrollPosition =
            Maybe.withDefault 0 model.lastScrollPosition

        top =
            Maybe.withDefault 0 model.styleTop
    in
    Options.apply summary
        Html.footer
        [ cs "mdc-bottombar"
        , when config.dense (cs cssClasses.dense)
        , when config.fixed (cs cssClasses.fixed)
        , when (config.fixed && lastScrollPosition > 0) <|
            cs cssClasses.scrolled
        , when config.prominent (cs cssClasses.prominent)
        , when config.short (cs cssClasses.short)
        , when (config.collapsed || (config.short && lastScrollPosition > 0)) <|
            cs cssClasses.collapsed
        , when (not config.fixed && not config.short) <|
            css "top" (String.fromFloat top ++ "px")
        , GlobalEvents.onScroll <|
            Json.map lift <|
                Json.map
                    (\scrollPosition ->
                        Scroll
                            { scrollPosition = scrollPosition }
                    )
                    getViewportScrollY
        , GlobalEvents.onResize <|
            Json.map lift <|
                Json.map2
                    (\scrollPosition topAppBarHeight ->
                        Resize
                            { scrollPosition = scrollPosition
                            , topAppBarHeight = topAppBarHeight
                            }
                    )
                    getViewportScrollY
                    getAppBarHeight
        , when
            (List.any identity
                [ model.lastScrollPosition == Nothing
                , model.topAppBarHeight == Nothing
                ]
            )
          <|
            GlobalEvents.onTick <|
                Json.map lift <|
                    Json.map2
                        (\scrollPosition topAppBarHeight ->
                            Init
                                { scrollPosition = scrollPosition
                                , topAppBarHeight = topAppBarHeight
                                }
                        )
                        getViewportScrollY
                        getAppBarHeight
        ]
        []
        [ row [] sections ]


row : List (Property m) -> List (Html m) -> Html m
row options =
    styled Html.div (cs "mdc-bottombar__row" :: options)



-- COMPONENT


type alias Store s =
    { s | topAppBar : Indexed Model }


getSet =
    Component.indexed .topAppBar (\x y -> { y | topAppBar = x }) defaultModel


react :
    (Internal.Msg.Msg m -> m)
    -> Msg
    -> Index
    -> Store s
    -> ( Maybe (Store s), Cmd m )
react =
    Component.react getSet.get getSet.set Internal.Msg.BottombarMsg (Component.generalise update)



-- API


type alias Property m =
    Options.Property Config m


view :
    (Internal.Msg.Msg m -> m)
    -> Index
    -> Store s
    -> List (Property m)
    -> List (Html m)
    -> Html m
view =
    Component.render getSet.get bottombar Internal.Msg.BottombarMsg


dense : Property m
dense =
    Options.option (\config -> { config | dense = True })


fixed : Property m
fixed =
    Options.option (\config -> { config | fixed = True })


prominent : Property m
prominent =
    Options.option (\config -> { config | prominent = True })


short : Property m
short =
    Options.option (\config -> { config | short = True })


collapsed : Property m
collapsed =
    Options.option (\config -> { config | collapsed = True })


hasActionItem : Property m
hasActionItem =
    cs "mdc-top-app-bar--short-has-action-item"


alignStart : Property m
alignStart =
    cs "mdc-top-app-bar__section--align-start"


alignEnd : Property m
alignEnd =
    cs "mdc-top-app-bar__section--align-end"


navigationIcon : List (Icon.Property m) -> String -> Html m
navigationIcon options name =
    Icon.view
        (cs "mdc-top-app-bar__navigation-icon"
            :: Icon.anchor
            :: options
        )
        name


section : List (Property m) -> List (Html m) -> Html m
section options =
    styled Html.section
        (cs "mdc-bottombar__section"
            :: options
        )


title : List (Property m) -> List (Html m) -> Html m
title options =
    styled Html.span
        (cs "mdc-top-app-bar__title"
            :: options
        )


actionItem : List (Icon.Property m) -> String -> Html m
actionItem options name =
    Icon.view
        (cs "mdc-top-app-bar__action-item"
            :: Icon.anchor
            :: options
        )
        name


icon : Icon.Property m
icon =
    cs "mdc-toolbar__icon"


fixedAdjust : Options.Property c m
fixedAdjust =
    cs "mdc-top-app-bar--fixed-adjust"


denseFixedAdjust : Options.Property c m
denseFixedAdjust =
    cs "mdc-top-app-bar--dense-fixed-adjust"


prominentFixedAdjust : Options.Property c m
prominentFixedAdjust =
    cs "mdc-top-app-bar--prominent-fixed-adjust"
