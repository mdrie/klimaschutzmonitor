module DecoderExtensions exposing (..)

import OptimizedDecoder as D


check : (b -> Bool) -> String -> D.Decoder b -> D.Decoder b
check assertion message decoder =
    assert decoder assertion message decoder


assert : D.Decoder a -> (a -> Bool) -> String -> D.Decoder b -> D.Decoder b
assert checkDecoder assertion message decoder =
    D.andThen
        (\checkVal ->
            if assertion checkVal then
                decoder

            else
                D.fail message
        )
        checkDecoder


optional : String -> D.Decoder a -> a -> D.Decoder a
optional fieldName decoder default =
    D.optionalField fieldName decoder |> D.map (Maybe.withDefault default)
