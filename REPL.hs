module REPL where

import Expr
import Parsing
import Data.Either

data State = State { vars :: [(Name, Int)],
                     numCalcs :: Int,
                     history :: [Command] }

initState :: State
initState = State [("it",0)] 0 []

-- Given a variable name and a value, return a new set of variables with
-- that name and value added.
-- If it already exists, remove the old value
updateVars :: Name -> Int -> [(Name, Int)] -> [(Name, Int)]
updateVars n x vars = dropVar n vars ++ [(n,x)]

-- Return a new set of variables with the given name removed
dropVar :: Name -> [(Name, Int)] -> [(Name, Int)]
dropVar n vars = filter (\(a,b) -> a /= n) vars

-- Add a command to the command history in the state
addHistory :: State -> Command -> State
addHistory st cmd = st {history = history st ++ [cmd]}

getCmd :: [Command] -> Int -> Command
getCmd cs n | length cs < n = error "Index too big"
            | otherwise     = cs!!(n-1)

process :: State -> Command -> IO ()
process st (Set var e)
     = do let st' = addHistory st (Set var e)
          let result = eval (vars st) e
          if var == "it" -- protecting 'it' variable from modifications & check for errors
            then do putStrLn("Cannot modify the implicit 'it' variable.")
                    repl st'
            else either x' y' result
              where
                x' xs = do putStrLn xs
                           repl st'
                y' x  = do putStrLn ("OK")
                           repl st' {vars = (updateVars var x (vars st))}

process st (Eval e)
     = do let st' = addHistory st (Eval e)
          let result = (eval (vars st') e)
          either x' y' result
          where
                x' xs = do putStrLn xs
                           repl st'
                y' x  = putStrLn (show x)
                           repl st' {numCalcs = numCalcs st + 1, vars = updateVars "it" x (vars st)}
process st (AccessCmdHistory n)
     = do let newCmd = getCmd (reverse (history st)) n
          process st newCmd
process st Quit
     = putStrLn("Bye")

-- Read, Eval, Print Loop
-- This reads and parses the input using the pCommand parser, and calls
-- 'process' to process the command.
-- 'process' will call 'repl' when done, so the system loops.

repl :: State -> IO ()
repl st = do putStr (show (numCalcs st) ++ " > ")
             inp <- getLine
             case parse pCommand inp of
                  [(cmd, "")] -> -- Must parse entire input
                          process st cmd
                  _ -> do putStrLn "Parse error"
                          repl st
