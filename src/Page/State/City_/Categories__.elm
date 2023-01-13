module Page.State.City_.Categories__ exposing (Data, Model, Msg, page)

import CategoryData exposing (allCategories)
import CategoryTree exposing (CategoryTree, CategoryTreeData, GoalState, categoryTree)
import CityData exposing (CityData, cityData, cityDataRecords)
import Css as C
import Css.Media as M
import DataSource exposing (DataSource)
import GoalData exposing (allGoals, goalData)
import Head
import Head.Seo as Seo
import Html.Styled exposing (..)
import Html.Styled.Attributes exposing (..)
import Link
import List.Extra
import Markdown exposing (toHtml)
import Maybe.Extra
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Route
import Shared
import Style exposing (subCss, theme)
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { city : String
    , categories : Maybe String
    }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }



-- ROUTES


routes : DataSource (List RouteParams)
routes =
    cityDataRecords
        |> DataSource.map (List.map routesPerCity)
        |> DataSource.resolve
        |> DataSource.map List.concat


routesPerCity : CityData -> DataSource (List RouteParams)
routesPerCity city =
    DataSource.map2 List.append
        (routesFromGoals city)
        (DataSource.succeed [ RouteParams city.id Nothing ])


routesFromGoals : CityData -> DataSource (List RouteParams)
routesFromGoals city =
    DataSource.map2
        (\a b ->
            List.append a b
                |> List.Extra.unique
                |> splitHierarchy
                |> List.map (routeFromCat city.id)
        )
        (catsFromStandardGoals city)
        (catsFromCityGoals city)


splitHierarchy : List String -> List String
splitHierarchy categories =
    let
        level : String -> List String
        level cat =
            let
                prefix =
                    if cat == "" then
                        cat

                    else
                        cat ++ "-"

                prefixLen =
                    String.length prefix

                levelCats =
                    categories
                        |> List.filter (String.startsWith prefix)
                        |> List.map
                            (\c ->
                                c
                                    |> String.dropLeft prefixLen
                                    |> String.split "-"
                                    |> List.head
                                    |> Maybe.withDefault ""
                            )
                        |> List.map (\levelCat -> prefix ++ levelCat)
                        |> List.Extra.unique
            in
            levelCats ++ List.concat (List.map level levelCats)
    in
    level ""


routeFromCat : String -> String -> RouteParams
routeFromCat city cat =
    if cat == "" then
        RouteParams city Maybe.Nothing

    else
        RouteParams city (Just cat)


catsFromStandardGoals : CityData -> DataSource (List String)
catsFromStandardGoals city =
    allGoals
        |> DataSource.map
            (\l ->
                l
                    |> List.filter (\gd -> List.any (\ggs -> List.member ggs city.goalsets) gd.goalsets)
                    |> List.map .category
            )


catsFromCityGoals : CityData -> DataSource (List String)
catsFromCityGoals city =
    city.goals
        |> List.map
            (\g ->
                goalData g.goal
                    |> DataSource.map .category
            )
        |> DataSource.combine



-- DATA


type alias Data =
    { city : CityData
    , navCategories : List CategoryTreeData
    , topCategory : CategoryTreeData
    }


data : RouteParams -> DataSource Data
data routeParams =
    let
        city : DataSource CityData
        city =
            cityData routeParams.city

        completeTree : DataSource CategoryTree
        completeTree =
            DataSource.map3 categoryTree city allCategories allGoals

        dummyData : CityData -> CategoryTree -> Data
        dummyData cty tree =
            Data cty [] (CategoryTreeData { id = "", title = "", description = "" } tree [])

        findSubtree : String -> CityData -> CategoryTree -> Data
        findSubtree searchCategory cty wholeTree =
            let
                findRecursive : List CategoryTreeData -> List CategoryTreeData -> Maybe Data
                findRecursive traversedNodes subTrees =
                    case subTrees of
                        [] ->
                            Nothing

                        firstTree :: restTrees ->
                            if firstTree.data.id == searchCategory then
                                Just (Data cty (List.reverse (firstTree :: traversedNodes)) firstTree)

                            else
                                findRecursive (firstTree :: traversedNodes) (CategoryTree.toList firstTree.subCategories)
                                    |> Maybe.Extra.orElse (findRecursive traversedNodes restTrees)
            in
            findRecursive [] (CategoryTree.toList wholeTree)
                |> Maybe.withDefault (dummyData cty (CategoryTree.fromList []))
    in
    case routeParams.categories of
        Nothing ->
            DataSource.map2 dummyData city completeTree

        Just catName ->
            DataSource.map2 (findSubtree catName) city completeTree


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "Klimaschutz Monitor " ++ static.data.city.name
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "Klimaschutz Monitor " ++ static.data.city.name
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "Klimaschutz Monitor " ++ static.data.city.name
        , locale = Nothing
        , title = "Klimaschutz Monitor " ++ static.data.city.name
        }
        |> Seo.website


type alias HtmlTag msg =
    List (Attribute msg) -> List (Html msg) -> Html msg


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

        myLink : String -> HtmlTag Msg
        myLink cat =
            Link.link (Link.Internal (Route.State__City___Categories__ { city = cityData.id, categories = Just cat }))
    in
    { title = "Klimaschutz Monitor " ++ cityData.name
    , body =
        [ div [ css [ C.width (C.pct 100), C.margin (C.px 3) ] ]
            [ div
                [ css
                    [ C.margin2 (C.px 3) (C.px 40)
                    , subCss "a" [ C.color theme.mainArea.textColor, C.fontSize (C.pt 15) ]
                    ]
                ]
                (if List.isEmpty static.data.navCategories then
                    []

                 else
                    Link.link (Link.Internal (Route.State__City___Categories__ { city = cityData.id, categories = Nothing })) [] [ text cityData.name ]
                        :: List.map (\cat -> myLink cat.data.id [] [ text cat.data.title ]) static.data.navCategories
                        |> List.intersperse (span [ css [ C.fontSize (C.pt 16) ] ] [ text " > " ])
                )
            , div
                [ css
                    [ C.displayFlex
                    , C.flexWrap C.wrap
                    ]
                ]
                (if List.isEmpty static.data.navCategories then
                    [ div
                        [ css
                            [ C.width (C.pct 100)
                            , M.withMedia [ M.all [ M.minWidth (C.px 1200) ] ] [ C.width (C.pct 50) ]
                            , M.withMedia [ M.all [ M.minWidth (C.px 900) ] ] [ C.width (C.pct 66.666) ]
                            , C.padding (C.px 20)
                            , subCss "p" [ C.textAlign C.justify ]
                            ]
                        ]
                        (h1 [] [ text ("Einleitung Kinmaschutz Monitor " ++ static.data.city.name) ]
                            :: toHtml static.data.city.introduction
                        )
                    , div
                        [ css
                            [ C.width (C.pct 100)
                            , M.withMedia [ M.all [ M.minWidth (C.px 1200) ] ] [ C.width (C.pct 50) ]
                            , M.withMedia [ M.all [ M.minWidth (C.px 900) ] ] [ C.width (C.pct 33.333) ]
                            , C.padding (C.px 20)
                            ]
                        ]
                        [ h1 [] [ text "Platzhalter für Charts etc." ]
                        ]
                    ]

                 else
                    []
                )
            , div
                [ css
                    [ C.displayFlex
                    , C.flexWrap C.wrap
                    ]
                ]
                (CategoryTree.toList static.data.topCategory.subCategories |> List.map (viewCategoryCard myLink))
            , div
                [ css
                    [ C.displayFlex
                    , C.flexWrap C.wrap
                    ]
                ]
                (static.data.topCategory.goalStates |> List.map viewGoalCard)
            ]
            |> toUnstyled
        ]
    }


viewGoalCard : GoalState -> Html Msg
viewGoalCard goalState =
    div
        [ css
            [ C.width (C.pct 100)
            , M.withMedia [ M.all [ M.minWidth (C.px 1200) ] ] [ C.width (C.pct 25) ]
            , M.withMedia [ M.all [ M.minWidth (C.px 900) ] ] [ C.width (C.pct 33.333) ]
            , M.withMedia [ M.all [ M.minWidth (C.px 600) ] ] [ C.width (C.pct 50) ]
            ]
        ]
        [ div
            [ css
                [ C.margin (C.px 10)
                , C.borderRadius (C.px 10)
                , C.backgroundColor theme.mainArea.tileColor
                , C.padding (C.px 10)
                , C.color theme.mainArea.textColor
                , subCss "a" [ C.color theme.mainArea.textColor, C.fontSize (C.pt 15) ]
                ]
            ]
            [ div
                [ css
                    [ C.displayFlex
                    , C.alignItems C.center
                    , C.padding (C.px 10)
                    , C.minHeight (C.px 65)
                    ]
                ]
                [ div [ css [ C.width (C.pct 100), C.fontSize (C.pt 14), C.fontWeight C.bolder ] ] [ text goalState.goalData.title ]
                , viewGoalState goalState
                ]
            , div [ css [ C.margin (C.px 5), C.padding (C.px 5), C.backgroundColor theme.mainArea.bgColor ] ] (toHtml goalState.goalData.description)
            , div [ css [ C.margin (C.px 5), C.padding (C.px 5), C.backgroundColor theme.mainArea.bgColor ] ] (toHtml goalState.description)
            ]
        ]


viewCategoryCard : (String -> HtmlTag Msg) -> CategoryTreeData -> Html Msg
viewCategoryCard myLink catTreeEntry =
    div
        [ css
            [ C.width (C.pct 100)
            , M.withMedia [ M.all [ M.minWidth (C.px 1200) ] ] [ C.width (C.pct 25) ]
            , M.withMedia [ M.all [ M.minWidth (C.px 900) ] ] [ C.width (C.pct 33.333) ]
            , M.withMedia [ M.all [ M.minWidth (C.px 600) ] ] [ C.width (C.pct 50) ]
            ]
        ]
        [ div
            [ css
                [ C.margin (C.px 10)
                , C.borderRadius (C.px 10)
                , C.backgroundColor theme.mainArea.tileColor
                , C.padding (C.px 10)
                , C.color theme.mainArea.textColor
                , subCss "a" [ C.color theme.mainArea.textColor, C.fontSize (C.pt 15) ]
                ]
            ]
            [ div [ css [ C.padding2 (C.px 10) (C.px 20) ] ]
                [ myLink catTreeEntry.data.id [ css [ C.width (C.pct 100) ] ] [ text catTreeEntry.data.title ]
                , div
                    [ css
                        [ C.displayFlex
                        , C.width (C.pct 100)
                        , C.height (C.px 10)
                        , C.borderRadius (C.px 3)
                        , C.overflow C.hidden
                        ]
                    ]
                    (progressBarEntries catTreeEntry)
                ]
            , viewSubCategories myLink catTreeEntry.subCategories
            , viewGoals catTreeEntry.goalStates
            ]
        ]


viewSubCategories : (String -> HtmlTag Msg) -> CategoryTree -> Html Msg
viewSubCategories myLink tree =
    case CategoryTree.toList tree of
        [] ->
            span [] []

        list ->
            div
                [ css
                    [ C.margin (C.px 9)
                    , C.padding (C.px 1)
                    ]
                ]
                (list
                    |> List.map
                        (\catTreeEntry ->
                            div
                                [ css
                                    [ C.displayFlex
                                    , C.alignItems C.center
                                    , C.margin (C.px 5)
                                    , C.padding (C.px 5)
                                    , C.backgroundColor theme.mainArea.subColor
                                    , C.borderRadius (C.px 5)
                                    ]
                                ]
                                [ myLink catTreeEntry.data.id [ css [ C.width (C.pct 100) ] ] [ text catTreeEntry.data.title ]
                                , div
                                    [ css
                                        [ C.displayFlex
                                        , C.width (C.px 30)
                                        , C.height (C.px 30)
                                        , C.borderRadius (C.px 5)
                                        , C.overflow C.hidden
                                        ]
                                    ]
                                    (progressBarEntries catTreeEntry)
                                ]
                        )
                )


progressBarEntries : CategoryTreeData -> List (Html Msg)
progressBarEntries catTreeEntry =
    let
        getGoals : CategoryTreeData -> List GoalState
        getGoals treeEntry =
            List.append treeEntry.goalStates
                (CategoryTree.toList treeEntry.subCategories
                    |> List.map getGoals
                    |> List.concat
                )

        goals =
            getGoals catTreeEntry

        numWithState state =
            goals |> List.filter (\g -> stringToStateValue g.state == state) |> List.length

        percentage state =
            toFloat (numWithState state) / toFloat (List.length goals) * 100.1
    in
    stateValues
        |> List.map
            (\state ->
                div [ css [ C.width (C.pct (percentage state)), C.backgroundColor (C.hex (Tuple.first (goalStateColorSymbol state))) ] ] []
            )


viewGoals : List CategoryTree.GoalState -> Html Msg
viewGoals goalStates =
    div []
        (goalStates
            |> List.map
                (\goalState ->
                    div
                        [ css
                            [ C.displayFlex
                            , C.alignItems C.center
                            , C.margin (C.px 5)
                            , C.padding (C.px 5)
                            , C.backgroundColor theme.mainArea.bgColor

                            -- , C.whiteSpace C.noWrap
                            -- , C.overflow C.hidden
                            -- , C.textOverflow C.ellipsis
                            ]
                        ]
                        [ div [ css [ C.width (C.pct 100) ] ] [ text goalState.goalData.title ]
                        , viewGoalState goalState
                        ]
                )
        )


viewGoalState : GoalState -> Html Msg
viewGoalState goalState =
    let
        ( color, symbol ) =
            goalStateColorSymbol (stringToStateValue goalState.state)
    in
    div
        [ css
            [ C.displayFlex
            , C.width (C.px 30)
            , C.borderRadius (C.px 5)
            , C.height (C.px 30)
            , C.backgroundColor (C.hex color)
            , C.color (C.hex "FFFFFF")
            , C.fontSize (C.px 30)
            , C.fontWeight C.bolder
            , C.justifyContent C.center
            , C.alignItems C.center
            ]
        ]
        [ text symbol ]


type StateValue
    = Unknown
    | Delayed
    | InProgress
    | Finished


stateValues : List StateValue
stateValues =
    [ Finished, InProgress, Unknown, Delayed ]


stringToStateValue : String -> StateValue
stringToStateValue string =
    case string of
        "in Arbeit" ->
            InProgress

        "verzögert/verfehlt" ->
            Delayed

        "abgeschlossen" ->
            Finished

        _ ->
            Unknown


goalStateColorSymbol : StateValue -> ( String, String )
goalStateColorSymbol state =
    case state of
        InProgress ->
            ( "FFAA00", "!" )

        Delayed ->
            ( "FF0000", "X" )

        Finished ->
            ( "00AA00", "✓" )

        Unknown ->
            ( "777777", "?" )
