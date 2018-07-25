module Material.Bottombar
    exposing
        ( actionItem
        , alignEnd
        , alignStart
        , collapsed
        , dense
        , denseFixedAdjust
        , fixed
        , fixedAdjust
        , icon
        , hasActionItem
        , navigationIcon
        , prominent
        , prominentFixedAdjust
        , Property
        , section
        , short
        , title
        , view
        )

{-| A top app bar is a container for items such as application title,
navigation icon, and action items.


# Resources

  - [Top App Bar - Internal.Components for the Web](https://material.io/develop/web/components/top-app-bar/)
  - [Material Design guidelines: Top app bar](https://material.io/go/design-app-bar-top)
  - [Demo](https://aforemny.github.io/elm-mdc/#top-app-bar)


# Example

    import Html exposing (text)
    import Material.Bottombar as Bottombar


    Bottombar.view Mdc "my-top-app-bar" model.mdc []
        [ Bottombar.fixed ]
        [ Bottombar.section [ Bottombar.alignStart ]
              [ Bottombar.navigationIcon [ Options.onClick OpenDrawer ] "menu"
              , Bottombar.title [] [ text title ]
              ]
          , Bottombar.section [ Bottombar.alignEnd ]
              [ Bottombar.actionItem [] "file_download"
              , Bottombar.actionItem [] "print"
              , Bottombar.actionItem [] "bookmark"
              ]
        ]


# Usage

@docs Property
@docs view


## Fixed variant

@docs fixed


## Dense varianet

@docs dense


## Prominent variant

@docs prominent


## Short variant

@docs short
@docs collapsed
@docs hasActionItem


## Sections

@docs section
@docs alignStart
@docs alignEnd


## Section elements

@docs navigationIcon
@docs title
@docs actionItem


## Fixed adjusts

@docs fixedAdjust
@docs denseFixedAdjust
@docs prominentFixedAdjust

-}

import Html exposing (Html)
import Material
import Internal.Component exposing (Index)
import Material.Icon as Icon
import Internal.Bottombar.Implementation as Bottombar
import Material.Options as Options


{-| Bottombar property.
-}
type alias Property m =
    Bottombar.Property m


{-| Bottombar view.
-}
view :
    (Material.Msg m -> m)
    -> Index
    -> Material.Model m
    -> List (Property m)
    -> List (Html m)
    -> Html m
view =
    Bottombar.view


{-| Bottombar section.

A Bottombar should have at least one section.

-}
section : List (Property m) -> List (Html m) -> Html m
section =
    Bottombar.section


{-| Add a title to the top app bar.
-}
title : List (Property m) -> List (Html m) -> Html m
title =
    Bottombar.title


{-| Action item placed on the side opposite of the navigation icon.
-}
actionItem : List (Icon.Property m) -> String -> Html m
actionItem options name =
    Bottombar.actionItem options name


{-| Make section align to the start.
-}
alignStart : Property m
alignStart =
    Bottombar.alignStart


{-| Make section align to the end.
-}
alignEnd : Property m
alignEnd =
    Bottombar.alignEnd


{-| Represent the navigation element in the top left corner.
-}
navigationIcon : List (Icon.Property m) -> String -> Html m
navigationIcon =
    Bottombar.navigationIcon


{-| Fixed top app bars stay at the top of the page and elevate above
the content when scrolled.
-}
fixed : Property m
fixed =
    Bottombar.fixed


{-| The dense top app bar is denser.
-}
dense : Property m
dense =
    Bottombar.dense


{-| The prominent top app bar is taller.
-}
prominent : Property m
prominent =
    Bottombar.prominent


{-| Short top app bars are top app bars that can collapse to the
navigation icon side when scrolled. Short top app bars should be used
with no more than 1 action item.
-}
short : Property m
short =
    Bottombar.short


{-| Short top app bars can be configured to always appear collapsed.
-}
collapsed : Property m
collapsed =
    Bottombar.collapsed


{-| Use this class if the short top app bar has an action item.
-}
hasActionItem : Property m
hasActionItem =
    Bottombar.hasActionItem


{-| Adds a top margin to the element so that it is not covered by a top app
bar.

Not only the `fixed` Bottombar requires this, but also the standard variant.
See below for special `dense` and `prominent` variants.

-}
fixedAdjust : Options.Property c m
fixedAdjust =
    Bottombar.fixedAdjust


{-| Adds a top margin to the element so that it is not covered by a dense top
app bar.
-}
denseFixedAdjust : Options.Property c m
denseFixedAdjust =
    Bottombar.denseFixedAdjust


{-| Style an icon as an icon at the end of the toolbar.

Should be applied to a `Icon.view`.

-}
icon : Icon.Property m
icon =
    Bottombar.icon


{-| Adds a top margin to the element so that it is not covered by a prominent
top app bar.
-}
prominentFixedAdjust : Options.Property c m
prominentFixedAdjust =
    Bottombar.prominentFixedAdjust
