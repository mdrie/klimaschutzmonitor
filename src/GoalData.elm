module GoalData exposing (GoalData, allGoals, goalData, goalDataFrom)

import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import Dict
import OptimizedDecoder as D


type alias GoalData =
    { id : String
    , title : String
    , category : String
    , categoryData : Maybe ()
    , goalsets : List String
    , weight : Int
    , description : String
    }


pathFromId : String -> String
pathFromId id =
    "content/goals/" ++ id ++ ".json"


goalIds : DataSource (List String)
goalIds =
    Glob.succeed identity
        |> Glob.match (Glob.literal "content/goals/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".json")
        |> Glob.toDataSource


allGoals : DataSource (List GoalData)
allGoals =
    goalIds
        |> DataSource.map (List.map goalData)
        |> DataSource.resolve


goalData : String -> DataSource GoalData
goalData id =
    id
        |> pathFromId
        |> DataSource.File.jsonFile
            (D.map7 GoalData
                (D.succeed id)
                (D.field "title" D.string)
                (D.field "category" D.string)
                (D.succeed Nothing)
                (D.field "goalsets" (D.list D.string))
                (D.field "weight" D.int)
                (D.field "description" D.string)
            )


goalDataFrom : Dict.Dict String GoalData -> String -> GoalData
goalDataFrom dict id =
    case Dict.get id dict of
        Just g ->
            g

        Nothing ->
            GoalData id ("Error: " ++ id ++ " not found.") "unknown" Nothing [] 0 ""
