module Page.Cities.City_ exposing (Data, Model, Msg, page)

import CategoryData exposing (CategoryData, allCategories)
import CategoryTree exposing (CategoryTree, GoalState, categoryTree)
import CityData exposing (..)
import DataSource exposing (DataSource)
import GoalData exposing (GoalData, allGoals)
import Head
import Head.Seo as Seo
import Html exposing (..)
import Html.Attributes exposing (style)
import Html.Styled
import Link
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Route
import Shared
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { city : String
    }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    cityDataRecords
        |> DataSource.map (List.map (\city -> RouteParams city.id))


type alias Data =
    { city : CityData
    , categories : List CategoryData
    , goals : List GoalData
    }


data : RouteParams -> DataSource Data
data routeParams =
    DataSource.map3 Data (cityData routeParams.city) allCategories allGoals


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Klimaschutz Monitor - " ++ static.data.city.name
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "city-game logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    let
        cityData : CityData
        cityData =
            static.data.city

        cats : List CategoryData
        cats =
            static.data.categories

        goals : List GoalData
        goals =
            static.data.goals

        catTree =
            categoryTree cityData cats goals

        printGoals : List GoalState -> Html Msg
        printGoals list =
            ul [ style "marginLeft" "20px", style "color" "blue" ] (list |> List.map (\g -> li [] [ text g.goalData.title ]))

        printCat : CategoryTree -> Html Msg
        printCat tree =
            ul [ style "marginLeft" "20px" ] (CategoryTree.toList tree |> List.map (\c -> li [] [ text c.data.title, printGoals c.goalStates, printCat c.subCategories ]))
    in
    { title = "Klimaschutz Monitor " ++ cityData.name
    , body =
        [ div []
            [ Link.link (Link.Internal (Route.State__City___Categories__ { city = cityData.id, categories = Nothing })) [] [ Html.Styled.text cityData.name ] |> Html.Styled.toUnstyled
            , p [] [ text (String.fromInt cityData.budget) ]
            , ul [] (cityData.goals |> List.map viewGoal)
            , p [] [ text ("Category Tree: " ++ String.fromInt (catTree |> CategoryTree.toList |> List.length)) ]
            , printCat catTree
            ]
        ]
    }


viewGoal : CityData.CityGoal -> Html Msg
viewGoal cityGoal =
    li []
        [ text
            (case cityGoal.goalData of
                Just d ->
                    d.title

                Nothing ->
                    cityGoal.goal
            )
        ]
