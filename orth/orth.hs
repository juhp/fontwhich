-- runghc orth.hs

import Data.List.Extra
import SimpleCmd
import System.Directory
import System.Environment
import System.FilePath

fcVersion = "2.16.1"

fclangDir ver = "fedora/rpms/fontconfig/BUILD/fontconfig-" ++ ver ++ "-build/fontconfig-" ++ ver ++ "/fc-lang"

main = do
  args <- getArgs
  langdir <-
    case args of
      [] -> do
        home <- getHomeDirectory
        return $ home </> fclangDir fcVersion
      [f] -> return f
      _ -> error' "Usage: orth path/to/fontconfig/fc-lang/"
  ls <- filesWithExtension langdir "orth"
  print $ map (replace "_" "-" . takeBaseName) ls

-- Take 1:
-- fontconfigLangs :: IO [String]
-- fontconfigLangs = do
--   ls <- cmdLines "fc-list" [":lang"]
--   let ls' = map (dropPrefix ":lang=") ls
--   return $ nubSort $ concatMap (splitOn "|") ls'
