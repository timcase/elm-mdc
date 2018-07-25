module Material.Internal.Bottombar.Implementation
    exposing
        ( alignEnd
        , alignStart
        , backgroundImage
        , fixed
        , fixedAdjust
        , fixedLastRow
        , flexible
        , flexibleDefaultBehavior
        , icon
        , iconToggle
        , menuIcon
        , Property
        , react
        , row
        , section
        , shrinkToFit
        , spaceAround
        , title
        , view
        , waterfall
        )

import Dict exposing (Dict)
import DOM
import Html.Attributes as Html
import Html exposing (Html, text)
import Json.Decode as Json exposing (Decoder)
import Material.Internal.Component as Component exposing (Indexed, Index)
import Material.Internal.GlobalEvents as GlobalEvents
import Material.Internal.Icon.Implementation as Icon
import Material.Internal.IconToggle.Implementation as IconToggle
import Material.Internal.Msg
import Material.Internal.Options as Options exposing (styled, cs, css, when, nop)
import Material.Internal.Bottombar.Model exposing (Model, defaultModel, Calculations, defaultCalculations, Config, defaultConfig, Geometry, Msg(..))


cssClasses :
    { fixed : String
    , fixedLastRow : String
    , fixedAtLastRow : String
    , bottombarRowFlexible : String
    , flexibleDefaultBehavior : String
    , flexibleMax : String
    , flexibleMin : String
    }
cssClasses =
    { fixed = "mdc-bottombar--fixed"
    , fixedLastRow = "mdc-toolbar--fixed-lastrow-only"
    , fixedAtLastRow = "mdc-toolbar--fixed-at-last-row"
    , bottombarRowFlexible = "mdc-toolbar--flexible"
    , flexibleDefaultBehavior = "mdc-toolbar--flexible-default-behavior"
    , flexibleMax = "mdc-toolbar--flexible-space-maximized"
    , flexibleMin = "mdc-toolbar--flexible-space-minimized"
    }


strings :
    { titleSelector : String
    , firstRowSelector : String
    , changeEvent : String
    }
strings =
    { titleSelector = "mdc-toolbar__title"
    , firstRowSelector = "mdc-toolbar__row:first-child"
    , changeEvent = "MDCToolbar:change"
    }


numbers :
    { minTitleSize : Float
    , maxTitleSize : Float
    , bottombarRowHeight : Float
    , bottombarRowMobileHeight : Float
    , bottombarMobileBreakpoint : Float
    }
numbers =
    { maxTitleSize = 2.125
    , minTitleSize = 1.25
    , bottombarRowHeight = 64
    , bottombarRowMobileHeight = 56
    , bottombarMobileBreakpoint = 600
    }


update : Msg -> Model -> ( Model, Cmd m )
update msg model =
    case msg of
        Init config geometry ->
            let
                calculations =
                    initKeyRatio config geometry
                        |> setKeyHeights geometry
            in
                ( { model
                    | geometry = Just geometry
                    , calculations = Just calculations
                    , config = Just config
                  }
                , Cmd.none
                )

        Resize config geometry ->
            let
                calculations =
                    Maybe.map (setKeyHeights geometry) model.calculations
            in
                ( { model
                    | geometry = Just geometry
                    , calculations = calculations
                    , config = Just config
                  }
                , Cmd.none
                )

        Scroll config scrollTop ->
            ( { model | scrollTop = scrollTop, config = Just config }, Cmd.none )


decodeGeometry : Decoder Geometry
decodeGeometry =
    let
        viewportWidth =
            DOM.target <|
                Json.at [ "ownerDocument", "defaultView", "innerWidth" ] Json.float

        getRowHeight =
            viewportWidth
                |> Json.map
                    (\viewportWidth ->
                        if viewportWidth < numbers.bottombarMobileBreakpoint then
                            numbers.bottombarRowMobileHeight
                        else
                            numbers.bottombarRowHeight
                    )

        getFirstRowElementOffsetHeight =
            firstRowElement DOM.offsetHeight

        firstRowElement decoder =
            DOM.target <|
                DOM.childNode 0 decoder

        getOffsetHeight =
            DOM.target <|
                DOM.offsetHeight
    in
        Json.map3
            (\getRowHeight getFirstRowElementOffsetHeight getOffsetHeight ->
                { getRowHeight = getRowHeight
                , getFirstRowElementOffsetHeight = getFirstRowElementOffsetHeight
                , getOffsetHeight = getOffsetHeight
                }
            )
            getRowHeight
            getFirstRowElementOffsetHeight
            getOffsetHeight


decodeScrollTop : Decoder Float
decodeScrollTop =
    DOM.target <|
        Json.at [ "ownerDocument", "defaultView", "scrollY" ] Json.float



-- VIEW


bottombar : (Msg -> m) -> Model -> List (Property m) -> List (Html m) -> Html m
bottombar lift model options nodes =
    let
        ({ config } as summary) =
            Options.collect defaultConfig options

        { bottombarProperties, flexibleRowElementStyles, elementStylesDefaultBehavior } =
            Maybe.map2
                (\geometry calculations ->
                    bottombarStyles config geometry model.scrollTop calculations
                )
                model.geometry
                model.calculations
                |> Maybe.map
                    (\styles ->
                        { bottombarProperties = Just styles.bottombarProperties
                        , flexibleRowElementStyles = styles.flexibleRowElementStyles
                        , elementStylesDefaultBehavior = styles.elementStylesDefaultBehavior
                        }
                    )
                |> Maybe.withDefault
                    { bottombarProperties = Nothing
                    , flexibleRowElementStyles = Nothing
                    , elementStylesDefaultBehavior = Nothing
                    }

        flexibleRowElementStylesHack =
            flexibleRowElementStyles
                |> Maybe.map
                    (\{ height } ->
                        let
                            className =
                                "mdc-toolbar-flexible-row-element-styles-hack-"
                                    ++ (String.join "-" (String.split "." height))

                            text =
                                "."
                                    ++ className
                                    ++ " .mdc-toolbar__row:first-child{height:"
                                    ++ height
                                    ++ ";}"
                        in
                            { className = className, text = text }
                    )

        elementStylesDefaultBehaviorHack =
            elementStylesDefaultBehavior
                |> Maybe.map
                    (\{ fontSize } ->
                        let
                            className =
                                "mdc-toolbar-flexible-default-behavior-hack-"
                                    ++ (String.join "-" (String.split "." fontSize))

                            text =
                                "."
                                    ++ className
                                    ++ " .mdc-toolbar__title{font-size:"
                                    ++ fontSize
                                    ++ ";}"
                        in
                            { className = className, text = text }
                    )

        backgroundImageHack =
            config.backgroundImage
                |> Maybe.map
                    (\backgroundImage ->
                        let
                            className =
                                (++) "mdc-toolbar-background-image-back-"
                                    (backgroundImage
                                        |> String.split "."
                                        |> String.join "-"
                                        |> String.split "/"
                                        |> String.join "-"
                                    )

                            text =
                                "."
                                    ++ className
                                    ++ " .mdc-toolbar__row:first-child::after {"
                                    ++ "background-image:url("
                                    ++ backgroundImage
                                    ++ ");"
                                    ++ "background-position:center;"
                                    ++ "background-size:cover;}"
                        in
                            { className = className, text = text }
                    )
    in
        Options.apply summary
            Html.footer
            (cs "mdc-bottombar"
                :: (when config.fixed <|
                        cs cssClasses.fixed
                   )
                :: (when (config.fixed && config.fixedLastrow) <|
                        cs cssClasses.fixedLastRow
                   )
                :: (when config.waterfall <|
                        cs "mdc-toolbar--waterfall"
                   )
                :: (when config.flexible <|
                        cs "mdc-toolbar--flexible"
                   )
                :: (when (config.flexible && config.useFlexibleDefaultBehavior) <|
                        cs "mdc-toolbar--flexible-default-behavior"
                   )
                :: (when (model.geometry == Nothing) <|
                        GlobalEvents.onTick (Json.map (lift << Init config) decodeGeometry)
                   )
                :: (GlobalEvents.onResize (Json.map (lift << Resize config) decodeGeometry))
                :: (GlobalEvents.onScroll (Json.map (lift << Scroll config) decodeScrollTop))
                :: (bottombarProperties
                        |> Maybe.map Options.many
                        |> Maybe.withDefault nop
                   )
                :: (flexibleRowElementStylesHack
                        |> Maybe.map (.className >> cs)
                        |> Maybe.withDefault nop
                   )
                :: (elementStylesDefaultBehaviorHack
                        |> Maybe.map (.className >> cs)
                        |> Maybe.withDefault nop
                   )
                :: (backgroundImageHack
                        |> Maybe.map (.className >> cs)
                        |> Maybe.withDefault nop
                   )
                :: options
            )
            []
            (nodes
                ++ [ Html.node "style"
                        [ Html.type_ "text/css"
                        ]
                        [ text <|
                            String.join "\n" <|
                                List.filterMap (Maybe.map .text)
                                    [ flexibleRowElementStylesHack
                                    , elementStylesDefaultBehaviorHack
                                    , backgroundImageHack
                                    ]
                        ]
                   ]
            )


adjustElementStyles : Config -> Calculations -> Maybe (Options.Property c m)
adjustElementStyles config calculations =
    let
        marginTop =
            calculations.bottombarHeight
    in
        if config.fixed then
            Just (css "margin-top" (toString marginTop ++ "px"))
        else
            Nothing


flexibleExpansionRatio : Calculations -> Float -> Float
flexibleExpansionRatio calculations scrollTop =
    let
        delta =
            0.0001
    in
        max 0 (1 - scrollTop / (calculations.flexibleExpansionHeight + delta))


initKeyRatio : Config -> Geometry -> Calculations
initKeyRatio config geometry =
    let
        bottombarRowHeight =
            geometry.getRowHeight

        firstRowMaxRatio =
            if bottombarRowHeight == 0 then
                0
            else
                geometry.getFirstRowElementOffsetHeight / bottombarRowHeight

        bottombarRatio =
            if bottombarRowHeight == 0 then
                0
            else
                geometry.getOffsetHeight / bottombarRowHeight

        flexibleExpansionRatio =
            firstRowMaxRatio - 1

        maxTranslateYRatio =
            if config.fixedLastrow then
                bottombarRatio - firstRowMaxRatio
            else
                0

        scrollThresholdRatio =
            if config.fixedLastrow then
                bottombarRatio - 1
            else
                firstRowMaxRatio - 1
    in
        { defaultCalculations
            | bottombarRatio = bottombarRatio
            , flexibleExpansionRatio = flexibleExpansionRatio
            , maxTranslateYRatio = maxTranslateYRatio
            , scrollThresholdRatio = scrollThresholdRatio
        }


setKeyHeights : Geometry -> Calculations -> Calculations
setKeyHeights geometry calculations =
    let
        bottombarRowHeight =
            geometry.getRowHeight

        bottombarHeight =
            calculations.bottombarRatio * bottombarRowHeight

        flexibleExpansionHeight =
            calculations.flexibleExpansionRatio * bottombarRowHeight

        maxTranslateYDistance =
            calculations.maxTranslateYRatio * bottombarRowHeight

        scrollThreshold =
            calculations.scrollThresholdRatio * bottombarRowHeight
    in
        { calculations
            | bottombarRowHeight = bottombarRowHeight
            , bottombarHeight = bottombarHeight
            , flexibleExpansionHeight = flexibleExpansionHeight
            , maxTranslateYDistance = maxTranslateYDistance
            , scrollThreshold = scrollThreshold
        }


bottombarStyles :
    Config
    -> Geometry
    -> Float
    -> Calculations
    ->
        { bottombarProperties : List (Property m)
        , flexibleRowElementStyles : Maybe { height : String }
        , elementStylesDefaultBehavior : Maybe { fontSize : String }
        }
bottombarStyles config geometry scrollTop calculations =
    let
        hasScrolledOutOfThreshold =
            scrollTop > calculations.scrollThreshold

        flexibleExpansionRatio_ =
            flexibleExpansionRatio calculations scrollTop

        bottombarFlexibleState =
            case flexibleExpansionRatio_ of
                1 ->
                    cs cssClasses.flexibleMax

                0 ->
                    cs cssClasses.flexibleMin

                _ ->
                    nop

        bottombarFixedState =
            let
                translateDistance =
                    max 0 <|
                        min (scrollTop - calculations.flexibleExpansionHeight) <|
                            (calculations.maxTranslateYDistance)
            in
                when config.fixedLastrow
                    << Options.many
                <|
                    [ css "transform" ("translateY(-" ++ toString translateDistance ++ "px)")
                    , when (translateDistance == calculations.maxTranslateYDistance) <|
                        cs cssClasses.fixedAtLastRow
                    ]

        flexibleRowElementStyles =
            if config.flexible && config.fixed then
                let
                    height =
                        calculations.flexibleExpansionHeight * flexibleExpansionRatio_
                in
                    Just { height = toString (height + calculations.bottombarRowHeight) ++ "px" }
            else
                Nothing

        elementStylesDefaultBehavior =
            if config.useFlexibleDefaultBehavior then
                let
                    maxTitleSize =
                        numbers.maxTitleSize

                    minTitleSize =
                        numbers.minTitleSize

                    currentTitleSize =
                        (maxTitleSize - minTitleSize)
                            * flexibleExpansionRatio_
                            + minTitleSize
                in
                    Just { fontSize = toString currentTitleSize ++ "rem" }
            else
                Nothing
    in
        { bottombarProperties =
            [ bottombarFlexibleState
            , bottombarFixedState
            ]
        , flexibleRowElementStyles =
            flexibleRowElementStyles
        , elementStylesDefaultBehavior =
            elementStylesDefaultBehavior
        }



-- COMPONENT


type alias Store s =
    { s | bottombar : Indexed Model }


( get, set ) =
    Component.indexed .bottombar (\x y -> { y | bottombar = x }) defaultModel


react :
    (Material.Internal.Msg.Msg m -> m)
    -> Msg
    -> Index
    -> Store s
    -> ( Maybe (Store s), Cmd m )
react =
    Component.react get set Material.Internal.Msg.BottombarMsg (Component.generalise update)



-- API


type alias Property m =
    Options.Property Config m


view :
    (Material.Internal.Msg.Msg m -> m)
    -> Index
    -> Store s
    -> List (Property m)
    -> List (Html m)
    -> Html m
view =
    Component.render get bottombar Material.Internal.Msg.BottombarMsg


fixed : Property m
fixed =
    Options.option (\config -> { config | fixed = True })


waterfall : Property m
waterfall =
    Options.option (\config -> { config | waterfall = True })


flexible : Property m
flexible =
    Options.option (\config -> { config | flexible = True })


flexibleDefaultBehavior : Property m
flexibleDefaultBehavior =
    Options.option (\config -> { config | useFlexibleDefaultBehavior = True })


fixedLastRow : Property m
fixedLastRow =
    Options.option (\config -> { config | fixedLastrow = True })


backgroundImage : String -> Property m
backgroundImage backgroundImage =
    Options.option (\config -> { config | backgroundImage = Just backgroundImage })


row : List (Property m) -> List (Html m) -> Html m
row options =
    styled Html.div
        (cs "mdc-toolbar__row"
            :: options
        )


section : List (Property m) -> List (Html m) -> Html m
section options =
    styled Html.section
        (cs "mdc-toolbar__section"
            :: options
        )


alignStart : Property m
alignStart =
    cs "mdc-toolbar__section--align-start"


alignEnd : Property m
alignEnd =
    cs "mdc-toolbar__section--align-end"


shrinkToFit : Property m
shrinkToFit =
    cs "mdc-toolbar__section--shrink-to-fit"


spaceAround : Property m
spaceAround =
    cs "mdc-toolbar__section--space-around"


menuIcon : Icon.Property m
menuIcon =
    cs "mdc-toolbar__menu-icon"


title : List (Property m) -> List (Html m) -> Html m
title options =
    styled Html.span
        (cs "mdc-toolbar__title"
            :: options
        )


icon : Icon.Property m
icon =
    cs "mdc-toolbar__icon"


iconToggle : IconToggle.Property m
iconToggle =
    cs "mdc-toolbar__icon"


fixedAdjust : Index -> Store s -> Options.Property c m
fixedAdjust index store =
    let
        model =
            Dict.get index store.bottombar
                |> Maybe.withDefault defaultModel

        styles =
            Maybe.map2 (,) model.config model.calculations
                |> Maybe.andThen
                    (\( config, calculations ) ->
                        adjustElementStyles config calculations
                    )
    in
        Options.many
            [ cs "mdc-toolbar-fixed-adjust"
            , Maybe.withDefault nop styles
            ]
