module CategoryData exposing (CategoryData, allCategories, categoryDataFrom)

import DataSource exposing (DataSource)
import DataSource.File
import DataSource.Glob as Glob
import DecoderExtensions as DE
import Dict
import OptimizedDecoder as D


type alias CategoryData =
    { id : String
    , title : String
    , description : String
    }


pathFromId : String -> String
pathFromId id =
    "content/categories/" ++ id ++ ".json"


categoryIds : DataSource (List String)
categoryIds =
    Glob.succeed identity
        |> Glob.match (Glob.literal "content/categories/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".json")
        |> Glob.toDataSource


allCategories : DataSource (List CategoryData)
allCategories =
    categoryIds
        |> DataSource.map (List.map categoryData)
        |> DataSource.resolve


categoryData : String -> DataSource CategoryData
categoryData id =
    id
        |> pathFromId
        |> DataSource.File.jsonFile
            (D.map3 CategoryData
                (D.field "id" D.string |> DE.check ((==) id) ("Filename " ++ id ++ ".json has to correspond to ID in file."))
                (D.field "title" D.string)
                (DE.optional "description" D.string "")
            )




categoryDataFrom : Dict.Dict String CategoryData -> String -> CategoryData
categoryDataFrom dict id =
    case Dict.get id dict of
        Just g ->
            g

        Nothing ->
            CategoryData id ("Error: " ++ id ++ " not found.") ""
