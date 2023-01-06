module Style exposing (theme, subCss)

import Css exposing (..)
import Css.Global

-- Colors generated with https://coolors.co/ffc80c (based on germanzero.de)
theme : { mainArea : { bgColor : Color, textColor : Color, headingColor: Color, tileColor : Color, subColor : Color }, header : { bgColor : Color, textColor : Color } }
theme =
    { mainArea =
        { bgColor = hex "ffffff"
        , textColor = hex "505050"-- "725700"-- "856600"-- "5F4900"
        , headingColor = hex "987400"
        , tileColor = hex "FFEBA8"
        , subColor = hex "FFDA62"
        }
    , header =
        { bgColor = hex "ffc80c"
        , textColor = hex "ffffff"
        }
    }


subCss : String -> List Style -> Style
subCss selector styleList =
    Css.Global.descendants [ Css.Global.selector selector styleList ]