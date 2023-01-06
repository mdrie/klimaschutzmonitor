module Link exposing (Target(..), link)

import Html.Styled as Html exposing (Attribute, Html)
import Html.Styled.Attributes as Attrs
import Path
import Route exposing (Route)


type Target
    = Internal Route
    | External String


ensureTrailingSlash : String -> String
ensureTrailingSlash str =
    if String.endsWith "/" str then
        str

    else
        String.append str "/"


toLink : (List (Attribute msg) -> tag) -> Target -> tag
toLink toAnchorTag target =
    let
        href =
            case target of
                Internal route ->
                    route |> Route.toPath |> Path.toAbsolute |> ensureTrailingSlash

                External url ->
                    url
    in
    toAnchorTag
        [ Attrs.href href
        , Attrs.attribute "elm-pages:prefetch" ""
        ]


link : Target -> List (Attribute msg) -> List (Html msg) -> Html msg
link target attributes children =
    toLink
        (\anchorAttrs ->
            Html.a
                (anchorAttrs ++ attributes)
                children
        )
        target
