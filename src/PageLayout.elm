module PageLayout exposing (pageLayout)

import Css exposing (..)
import Css.Global as Global
import Css.Media as M
import Css.Transitions as T
import Html as OldH
import Html.Styled exposing (..)
import Html.Styled.Attributes as A
import Link
import Route
import Style exposing (theme)
import View exposing (View)


globalStyle : Html msg
globalStyle =
    Global.global
        [ Global.everything
            [ margin zero
            , textDecoration none
            , boxSizing borderBox
            , fontFamilies [ qt "Droid Sans Mono", qt "Meleno Monaco", qt "Consolas", qt "Courrier New", .value monospace ]
            ]
        , Global.h1
            [ fontSize (pt 16)
            , color theme.mainArea.headingColor
            , padding2 (px 10) (px 0)
            ]
        , Global.h2
            [ fontSize (pt 14)
            , color theme.mainArea.headingColor
            , padding2 (px 7) (px 0)
            ]
        , Global.h3
            [ fontSize (pt 12)
            , color theme.mainArea.headingColor
            , padding2 (px 5) (px 0)
            ]
        , Global.p
            [ padding2 (px 5) (px 0)

            --, fontFamilies [ qt "Droid Sans", qt "Helvetica", qt "Arial", .value sansSerif ]
            ]
        ]


headerHeight : Px
headerHeight =
    px 100


headerStyle : Style
headerStyle =
    batch
        [ backgroundColor theme.header.bgColor
        , height headerHeight
        , width (pct 100)
        ]


mobileMaxWidth : number
mobileMaxWidth =
    1050


mediaMobile : List Style -> Style
mediaMobile =
    M.withMedia [ M.all [ M.maxWidth (px mobileMaxWidth) ] ]


mediaDesktop : List Style -> Style
mediaDesktop =
    M.withMedia [ M.all [ M.minWidth (px (mobileMaxWidth + 1)) ] ]


titleStyle : Style
titleStyle =
    batch
        [ color theme.header.textColor
        , fontWeight bold
        , height headerHeight
        , padding zero
        , float left
        , display inlineFlex
        , alignItems center
        , mediaDesktop
            [ fontSize (px 50)
            , marginLeft (px 40)
            ]
        , mediaMobile
            [ fontSize (px 25)
            , marginLeft (px 10)
            , marginRight (px 100)
            ]
        ]


menuStyle : { menu : Style, expandedMenu : Style, item : Style, button : Style, active : Style, hamburgerBtn : Style }
menuStyle =
    let
        buttonActive =
            [ color theme.header.bgColor
            , backgroundColor theme.header.textColor
            ]
    in
    { menu =
        batch
            [ position absolute
            , right zero
            , marginRight (px 20)
            , mediaMobile
                [ position fixed
                , marginRight zero
                , width (pct 100)
                , height (vh 100)
                , backgroundColor theme.header.bgColor
                , right (pct -100)
                , textAlign center
                , T.transition [ T.right 500 ]
                ]
            ]
    , expandedMenu =
        batch
            [ mediaMobile
                [ right zero ]
            ]
    , item =
        batch
            [ display inlineBlock
            , lineHeight headerHeight
            , margin2 zero (px 5)
            , mediaMobile
                [ display block
                , margin2 (px 50) zero
                , lineHeight (px 30)
                ]
            ]
    , button =
        batch
            [ color theme.header.textColor
            , fontSize (px 17)
            , padding2 (px 7) (px 13)
            , borderRadius (px 3)
            , textTransform uppercase
            , hover buttonActive
            , T.transition
                [ T.background 500
                , T.color 250
                ]
            , mediaMobile
                [ fontSize (px 20)
                ]
            ]
    , active = batch buttonActive
    , hamburgerBtn =
        batch
            [ position absolute
            , right zero
            , fontSize (px 30)
            , color theme.header.textColor
            , lineHeight headerHeight
            , marginRight (px 40)
            , cursor pointer
            , display none
            , mediaMobile
                [ display block
                ]
            ]
    }


checkTogglesMenu : Style -> Html msg
checkTogglesMenu style =
    Global.global
        [ Global.selector "#hamburger-check:not(:checked)"
            [ Global.generalSiblings
                [ Global.class "menu" [ style ] ]
            ]
        ]


pageLayout : Route.Route -> Bool -> View msg -> OldH.Html msg
pageLayout currentRoute showMobileMenu pageView =
    div []
        [ globalStyle
        , nav [ A.css [ headerStyle ] ]
            [ p [ A.css [ titleStyle ] ] [ label [] [ text pageView.title ] ]
            , input [ A.type_ "checkbox", A.checked (not showMobileMenu), A.id "hamburger-check", A.css [ display none ] ] []
            , label [ A.for "hamburger-check", A.css [ menuStyle.hamburgerBtn ] ] [ text "☰" ]
            , ul [ A.css [ menuStyle.menu ], A.class "menu" ]
                [ menuEntry currentRoute (Link.Internal Route.Index) "Städte"
                , menuEntry currentRoute (Link.External "https://github.com/mdrie/klimaschutzmonitor") "GitHub"
                ]
            ]
        , checkTogglesMenu menuStyle.expandedMenu
        , div [ A.css [ width (pct 100), displayFlex, justifyContent center ] ] (List.map fromUnstyled pageView.body)
        ]
        |> toUnstyled


menuEntry : Route.Route -> Link.Target -> String -> Html msg
menuEntry currentPath linkPath menuText =
    let
        isActive =
            case linkPath of
                Link.Internal route ->
                    currentPath == route

                Link.External _ ->
                    False

        attrList =
            if isActive then
                [ menuStyle.active ]

            else
                []
    in
    li [ A.for "hamburger-check", A.css [ menuStyle.item ] ] [ Link.link linkPath [ A.css (menuStyle.button :: attrList) ] [ text menuText ] ]
