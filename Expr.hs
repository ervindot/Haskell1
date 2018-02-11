module Expr where

import Parsing
import Control.Applicative

type Name = String

-- At first, 'Expr' contains only addition and values. You will need to
-- add other operations, and variables
data Expr = Add Expr Expr
          | Subtract Expr Expr
          | Multiply Expr Expr
          | Divide Expr Expr
          | Val Int
  deriving Show

-- These are the REPL commands - set a variable name to a value, and evaluate
-- an expression
data Command = Set Name Expr
             | Eval Expr
  deriving Show

eval :: [(Name, Int)] -> -- Variable name to value mapping
        Expr -> -- Expression to evaluate
        Maybe Int -- Result (if no errors such as missing variables)
eval vars (Val x) = Just x -- for values, just give the value directly
eval vars (Add x y) = Just (+) <*> eval vars y <*> eval vars x
eval vars (Subtract x y) = Just (-) <*> eval vars x <*> eval vars y
eval vars (Multiply x y) = Just (*) <*> eval vars x <*> eval vars y
eval vars (Divide x y) = Just (div) <*> eval vars x <*> eval vars y --currently returns ints

digitToInt :: Char -> Int
digitToInt x = fromEnum x - fromEnum '0'

pCommand :: Parser Command
pCommand = do t <- letter
              char '='
              e <- pExpr
              return (Set [t] e)
            ||| do e <- pExpr
                   return (Eval e)

pExpr :: Parser Expr
pExpr = do t <- pTerm
           do char '+'
              e <- pExpr
              return (Add t e)
            ||| do char '-'
                   e <- pExpr
                   return (Subtract t e)
                   --error "Subtraction not yet implemented!"
                 ||| return t

pFactor :: Parser Expr
pFactor = do d <- digit
             return (Val (digitToInt d))
           ||| do v <- letter
                  error "Variables not yet implemented"
                ||| do char '('
                       e <- pExpr
                       char ')'
                       return e

pTerm :: Parser Expr
pTerm = do f <- pFactor
           do char '*'
              t <- pTerm
              return (Multiply f t)
              --error "Multiplication not yet implemented"
            ||| do char '/'
                   t <- pTerm
                   return (Divide f t)
                   --error "Division not yet implemented"
                 ||| return f