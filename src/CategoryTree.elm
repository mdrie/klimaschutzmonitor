module CategoryTree exposing (CategoryTree, CategoryTreeData, GoalState, categoryTree, fromList, toList)

import CategoryData exposing (CategoryData, categoryDataFrom)
import CityData exposing (CityData, CityGoal)
import Dict
import GoalData exposing (GoalData, goalDataFrom)
import List.Extra


type alias CategoryTreeData =
    { data : CategoryData
    , subCategories : CategoryTree
    , goalStates : List GoalState
    }


type CategoryTree
    = CategoryHierarchy (List CategoryTreeData)


type alias GoalState =
    { goalData : GoalData
    , state : String
    , description : String
    }


toList : CategoryTree -> List CategoryTreeData
toList (CategoryHierarchy list) =
    list


fromList : List CategoryTreeData -> CategoryTree
fromList list =
    CategoryHierarchy list


idListToDict : List { a | id : String } -> Dict.Dict String { a | id : String }
idListToDict list =
    list
        |> List.map (\b -> ( b.id, b ))
        |> Dict.fromList


categoryTree : CityData -> List CategoryData -> List GoalData -> CategoryTree
categoryTree city categoryList goalList =
    let
        cats : Dict.Dict String CategoryData
        cats =
            idListToDict categoryList

        goals =
            idListToDict goalList

        cityGoalToGoalState : CityGoal -> GoalState
        cityGoalToGoalState cg =
            GoalState (goalDataFrom goals cg.goal) cg.state cg.description

        cityGoalStates : List GoalState
        cityGoalStates =
            city.goals |> List.map cityGoalToGoalState

        isInCityGoalset : GoalData -> Bool
        isInCityGoalset goal =
            List.any (\ggs -> List.member ggs city.goalsets) goal.goalsets

        standardGoalStates : List GoalState
        standardGoalStates =
            goalList
                |> List.filter (\g -> isInCityGoalset g && not (List.any (\cg -> cg.goalData.id == g.id) cityGoalStates))
                |> List.map (\g -> GoalState g "unknown" "")

        goalStates : List GoalState
        goalStates =
            List.append cityGoalStates standardGoalStates |> List.sortBy (\g -> g.state) |> List.reverse

        cityCategories : List String
        cityCategories =
            goalStates |> List.map (\g -> g.goalData.category)

        nextLevelCats : String -> List CategoryData
        nextLevelCats cat =
            let
                prefix =
                    if cat == "" then
                        cat

                    else
                        cat ++ "-"

                prefixLen =
                    String.length prefix
            in
            cityCategories
                |> List.filter (String.startsWith prefix)
                |> List.map
                    (\c ->
                        String.dropLeft prefixLen c
                            |> String.split "-"
                            |> List.head
                            |> Maybe.withDefault ""
                    )
                -- |> Debug.log "Cats: "
                |> List.Extra.unique
                |> List.map (\id -> categoryDataFrom cats (prefix ++ id))

        goalStatesForCat catId =
            goalStates
                |> List.filter (\gs -> gs.goalData.category == catId)

        subTree : String -> CategoryTree
        subTree cat =
            nextLevelCats cat
                |> List.map
                    (\c ->
                        { data = c
                        , subCategories = subTree c.id
                        , goalStates = goalStatesForCat c.id
                        }
                    )
                |> CategoryHierarchy
    in
    subTree ""
