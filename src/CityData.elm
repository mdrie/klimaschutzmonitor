module CityData exposing (CityData, CityGoal, cityData, cityDataRecords, cityDataGoals)

import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import GoalData exposing (..)
import OptimizedDecoder as D


type alias CityFile =
    { id : String
    , path : String
    }


cityFiles : DataSource (List CityFile)
cityFiles =
    Glob.succeed CityFile
        |> Glob.match (Glob.literal "content/cities/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".json")
        |> Glob.captureFilePath
        |> Glob.toDataSource


pathFromId : String -> String
pathFromId id =
    "content/cities/" ++ id ++ ".json"


type alias CityData =
    { id : String
    , path : String
    , route : String
    , name : String
    , budget : Int
    , introduction : String
    , goalsets : List String
    , goals : List CityGoal
    }


type alias CityGoal =
    { goal : String
    , state : String
    , description : String
    , goalData : Maybe GoalData
    }


cityDataRecords : DataSource (List CityData)
cityDataRecords =
    cityFiles
        |> DataSource.map (List.map cityDataRecord)
        |> DataSource.resolve


cityDataRecord : CityFile -> DataSource CityData
cityDataRecord cityFile =
    cityFile.path
        |> DataSource.File.jsonFile
            (D.map8 (DataSource.map8 CityData)
                (D.succeed cityFile.id |> D.map DataSource.succeed)
                (D.succeed cityFile.path |> D.map DataSource.succeed)
                (D.succeed ("/state/" ++ cityFile.id ++ "/") |> D.map DataSource.succeed)
                (D.field "name" D.string |> D.map DataSource.succeed)
                (D.field "budget" D.int |> D.map DataSource.succeed)
                (D.field "introduction" D.string |> D.map DataSource.succeed)
                (D.field "goalsets" (D.list D.string |> D.map DataSource.succeed))
                (D.field "goals"
                    (D.list
                        (D.map4 (DataSource.map4 CityGoal)
                            (D.field "goal" D.string |> D.map DataSource.succeed)
                            (D.field "state" D.string |> D.map DataSource.succeed)
                            (D.field "description" D.string |> D.map DataSource.succeed)
                            (D.field "goal" D.string
                                |> D.map goalData
                                |> D.map (DataSource.map Just)
                            )
                        )
                    )
                    |> D.map DataSource.combine
                )
            )
        |> DataSource.andThen identity


cityDataGoals : CityFile -> DataSource { name : String, goals : List (Maybe GoalData) }
cityDataGoals cityFile =
    cityFile.path
        |> DataSource.File.jsonFile
            (D.map2 (DataSource.map2 (\n gls -> { name = n, goals = gls }))
                (D.field "name" D.string |> D.map DataSource.succeed)
                (D.field "goals"
                    (D.list
                        (D.field "goal" D.string
                            |> D.map goalData
                            |> D.map (DataSource.map Just)
                        )
                    )
                    |> D.map DataSource.combine
                )
            )
        |> DataSource.andThen identity



-- cityDataFull cityFile =
--     cityDataRecord cityFile
--     |> DataSource.andThen augmentCityData
-- augmentCityData : CityData -> DataSource CityData
-- augmentCityData cData =
--     DataSource.map {cData | goals = cData.goals |> List.map addGoalData}
-- addGoalData : CityGoal -> CityGoal
-- addGoalData goal =
--     {goal | goalData = Just (goalData goal.goal)}


cityData : String -> DataSource CityData
cityData id =
    cityDataRecord { id = id, path = pathFromId id }
