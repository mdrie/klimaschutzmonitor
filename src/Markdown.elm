module Markdown exposing (toHtml)

import Html
import Html.Styled exposing (Html, fromUnstyled, text)
import Markdown.Block
import Markdown.Parser
import Markdown.Renderer
import Parser
import Parser.Advanced as Advanced


toHtml : String -> List (Html msg)
toHtml markdown =
    Markdown.Parser.parse markdown
        |> Result.mapError deadEndsToString
        |> Result.andThen renderParsed
        |> handleError


renderParsed : List Markdown.Block.Block -> Result String (List (Html msg))
renderParsed ast =
    Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer ast
        |> Result.andThen convertFromUnstyled


convertFromUnstyled : List (Html.Html msg) -> Result String (List (Html msg))
convertFromUnstyled unstyleds =
    Ok (List.map fromUnstyled unstyleds)


deadEndsToString : List (Advanced.DeadEnd String Parser.Problem) -> String
deadEndsToString deadEnds =
    deadEnds
        |> List.map Markdown.Parser.deadEndToString
        |> String.join "\n"


handleError : Result String (List (Html msg)) -> List (Html msg)
handleError result =
    case result of
        Ok htmlList ->
            htmlList

        Err prob ->
            [ text prob ]
