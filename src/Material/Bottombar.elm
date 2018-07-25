module Material.Bottombar
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
        , row
        , section
        , shrinkToFit
        , spaceAround
        , title
        , view
        , waterfall
        )

{-| A toolbar is a container for multiple rows that contain items such as the
application's title, navigation menu and tabs, among other things.

By default a toolbar scrolls with the view. You can change this using the
`fixed` or `waterfall` properties. A `flexible` toolbar changes its height when
the view is scrolled.


# Resources

  - [Material Design guidelines: Bottombars](https://material.io/guidelines/components/toolbars.html)
  - [Demo](https://aforemny.github.io/elm-mdc/#toolbar)


# Example

    import Html exposing (text)
    import Material.Bottombar as Bottombar


    Bottombar.view Mdc [0] model.mdc []
        [ Bottombar.row []
              [ Bottombar.section
                    [ Bottombar.alignStart
                    ]
                    [ Bottombar.menuIcon [] "menu"
                    , Bottombar.title [] [ text "Title" ]
                    ]
              , Bottombar.section
                    [ Bottombar.alignEnd
                    ]
                    [ Bottombar.icon [] "file_download"
                    , Bottombar.icon [] "print"
                    , Bottombar.icon [] "bookmark"
                    ]
              ]
        ]


# Usage

@docs Property
@docs view
@docs fixed
@docs waterfall
@docs flexible
@docs flexibleDefaultBehavior
@docs fixedLastRow
@docs backgroundImage
@docs row
@docs section
@docs alignStart
@docs alignEnd
@docs shrinkToFit
@docs menuIcon
@docs title
@docs icon, iconToggle
@docs fixedAdjust

-}

import Html exposing (Html)
import Material
import Material.Component exposing (Index)
import Material.Icon as Icon
import Material.IconToggle as IconToggle
import Material.Internal.Bottombar.Implementation as Bottombar
import Material.Options as Options


{-| Bottombar property.
-}
type alias Property m =
    Bottombar.Property m


{-| Bottombar view.

The first child of this function has to be a `row`.

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


{-| Make the toolbar fixed to the top and apply a persistent elevation.
-}
fixed : Property m
fixed =
    Bottombar.fixed


{-| Make the toolbar gain elevation only when the window is scrolled.
-}
waterfall : Property m
waterfall =
    Bottombar.waterfall


{-| Make the height of the toolbar change as the window is scrolled.

You will likely want to specify `flexibleDefaultBehavior` as well.

-}
flexible : Property m
flexible =
    Bottombar.flexible


{-| Make use of the flexible default behavior.
-}
flexibleDefaultBehavior : Property m
flexibleDefaultBehavior =
    Bottombar.flexibleDefaultBehavior


{-| Make the last row of the toolbar fixed.
-}
fixedLastRow : Property m
fixedLastRow =
    Bottombar.fixedLastRow


{-| Add a background image to the toolbar.
-}
backgroundImage : String -> Property m
backgroundImage =
    Bottombar.backgroundImage


{-| Bottombar row.

A row is divided into several `section`s. There has to be at least one row as
direct child of `view`.

-}
row : List (Property m) -> List (Html m) -> Html m
row =
    Bottombar.row


{-| Bottombar section.

By default sections share the available space of a row equally.

Has to be a child of `row`.

-}
section : List (Property m) -> List (Html m) -> Html m
section =
    Bottombar.section


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


{-| Make spaceAround
-}
spaceAround : Property m
spaceAround =
    Bottombar.spaceAround


{-| Make a section take the width of its contents.
-}
shrinkToFit : Property m
shrinkToFit =
    Bottombar.shrinkToFit


{-| Style an icon to be the menu icon of the toolbar.
-}
menuIcon : Icon.Property m
menuIcon =
    Bottombar.menuIcon


{-| Add a title to the toolbar.

Has to be a child of `section`.

-}
title : List (Property m) -> List (Html m) -> Html m
title =
    Bottombar.title


{-| Style an icon as an icon at the end of the toolbar.

Should be applied to a `Icon.view`.

-}
icon : Icon.Property m
icon =
    Bottombar.icon


{-| Style an icon toggle as an icon at the end of the toolbar.

Should be applied to a `IconToggle.view`.

-}
iconToggle : IconToggle.Property m
iconToggle =
    Bottombar.iconToggle


{-| Adds a top margin to the element so that it is not covered by the toolbar.

Should be applied to a direct sibling of `view`.

-}
fixedAdjust : Index -> Material.Model m -> Options.Property c m
fixedAdjust =
    Bottombar.fixedAdjust
