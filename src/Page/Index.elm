module Page.Index exposing (Data, Model, Msg, page)

import Browser.Navigation
import CityData exposing (CityData, cityDataRecords)
import Css as C
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Link
import Markdown.Block exposing (Inline(..))
import Page exposing (StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Route
import Shared
import Style exposing (subCss, theme)
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    ()


type alias RouteParams =
    {}


page : Page.PageWithState RouteParams Data Model Msg
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { view = view
            , init = \_ _ _ -> ( (), Cmd.none )
            , update = update
            , subscriptions = \_ _ _ _ -> Sub.none
            }


update : PageUrl -> Maybe Browser.Navigation.Key -> Shared.Model -> StaticPayload templateData routeParams -> Msg -> Model -> ( Model, Cmd Msg )
update _ navKey _ _ msg _ =
    case ( navKey, msg ) of
        _ ->
            ( (), Cmd.none )


data : DataSource Data
data =
    cityDataRecords


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Klimaschutz Monitor"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "Klimaschutz Monitor"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Klimaschutz Monitor"
        , locale = Nothing
        , title = "Klimaschutz Monitor"
        }
        |> Seo.website


type alias Data =
    List CityData


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ _ static =
    { title = "Klimaschutz Monitor"
    , body =
        [ div [ css [ C.width (C.px 250) ] ]
            (List.map cityButton static.data)
            |> toUnstyled
        ]
    }


cityButton : CityData -> Html Msg
cityButton city =
    div
        [ css
            [ C.margin (C.px 10)
            , C.borderRadius (C.px 10)
            , C.backgroundColor theme.mainArea.tileColor
            , C.padding (C.px 10)
            , C.color theme.mainArea.textColor
            , C.textAlign C.center
            , subCss "a" [ C.color theme.mainArea.textColor, C.fontSize (C.pt 15) ]
            ]
        ]
        [ Link.link (Link.Internal (Route.State__City___Categories__ { city = city.id, categories = Nothing })) [] [ text city.name ] ]
