{-# LANGUAGE CPP            #-}
{-# LANGUAGE LambdaCase     #-}
{-# LANGUAGE NamedFieldPuns #-}
module Main (main) where

import           Control.Monad (when)
import           Data.Bits     (shift, (.&.))
import           Data.Word     (Word16, Word32)

#include "errors.h"

foreign import ccall "test_main" c_test_main :: Bool -> Word16 -> IO Word32


data Result = Result
  { line   :: Int
  , result :: Int
  , errno  :: Int
  }

testMain :: Bool -> Int -> IO Result
testMain collectSamples port = do
  result <- c_test_main collectSamples (fromIntegral port)
  let line   = fromIntegral $ shift result (-16)
  let errno  = fromIntegral $ shift result (- 8) .&. 0xff
  let result = fromIntegral $       result       .&. 0xff
  return $ Result line result errno


errorDesc :: Int -> String
errorDesc = \case
  E_OK      -> "Success"
  E_NOMEM   -> "Error: Out of memory"
  E_BIND    -> "Error: bind failed"
  E_LISTEN  -> "Error: listen failed"
  E_ACCEPT  -> "Error: accept failed"
  E_PARSE   -> "Error: unable to parse msgpack input"
  E_OPEN    -> "Error: open failed"
  E_READ    -> "Error: read failed"
  E_WRITE   -> "Error: write failed"
  e         -> "Unknown error code: " ++ show e


main :: IO ()
main = do
  Result { line, result, errno } <- testMain True 1234
  when (result /= E_OK) $
    putStrLn $ errorDesc result ++ ", errno=" ++ show errno ++ ", line=" ++ show line