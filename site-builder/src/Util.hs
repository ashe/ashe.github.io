module Util
( getSlug
, shuffle
, cleanIndexUrls
, localAssetsUrls
) where

import Hakyll
import Data.Char (isLetter, toLower)
import Data.List (isPrefixOf, isSuffixOf)
import Data.Map (Map, elems, insert, singleton, (!))
import System.FilePath.Posix (takeBaseName, (</>))
import System.Random (RandomGen, StdGen, randomR, mkStdGen)

--------------------------------------------------------------------------------

getSlug :: Item String -> String
getSlug = map toLower . filter isLetter . file
  where file = takeBaseName . toFilePath . itemIdentifier


shuffle :: [a] -> [a]
shuffle [] = []
shuffle l = fst <$> toElems $ 
  foldl fisherYatesStep (initial (head l) gen) (numerate (tail l))
  where gen = mkStdGen 0
        toElems (x, y) = (elems x, y)
        numerate = zip [1..]
        initial x gen = (singleton 0 x, gen)


cleanIndexUrls :: Item String -> Compiler (Item String)
cleanIndexUrls = let
  cleanIndex :: String -> String
  cleanIndex url
      | isSuffixOf idx url = take (length url - length idx) url
      | otherwise = url
      where idx = "index.html"
  in pure . fmap (withUrls cleanIndex)


localAssetsUrls :: Item String -> Compiler (Item String)
localAssetsUrls item = let
  localAssets :: FilePath -> FilePath
  localAssets url
      | isPrefixOf "./" url && local /= "index" = "../" </> local </> drop 2 url
      | otherwise = url
  ident = itemIdentifier item
  file = toFilePath ident
  local = takeBaseName file
  in pure $ fmap (withUrls localAssets) item

--------------------------------------------------------------------------------

fisherYatesStep :: RandomGen g => (Map Int a, g) -> (Int, a) -> (Map Int a, g)
fisherYatesStep (m, gen) (i, x) = ((insert j x . insert i (m ! j)) m, gen')
  where
    (j, gen') = randomR (0, i) gen