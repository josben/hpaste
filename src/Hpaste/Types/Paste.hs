{-# OPTIONS -Wall -fno-warn-orphans #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}

-- | The paste type.

module Hpaste.Types.Paste
       (Paste(..)
       ,PasteType(..)
       ,PasteSubmit(..)
       ,PasteFormlet(..)
       ,ExprFormlet(..)
       ,PastePage(..)
       ,StepsPage(..)
       ,Hint(..)
       ,ReportFormlet(..)
       ,ReportSubmit(..))
       where

import Hpaste.Types.Newtypes
import Hpaste.Types.Language
import Hpaste.Types.Channel

import Blaze.ByteString.Builder                (toByteString)
import Blaze.ByteString.Builder.Char.Utf8      as Utf8 (fromString)
import Data.Text                               (Text,pack)
import Data.Time                               (UTCTime,zonedTimeToUTC)
import Database.PostgreSQL.Simple.Param        (Param(..),Action(..))
import Database.PostgreSQL.Simple.QueryResults (QueryResults(..))
import Database.PostgreSQL.Simple.Result       (Result(..))
import Language.Haskell.HLint                  (Severity)
import Snap.Core                               (Params)
import Text.Blaze                              (ToHtml(..),toHtml)
import Text.Blaze.Html5                        (Html)

-- | A paste.
data Paste = Paste {
   pasteId       :: PasteId
  ,pasteTitle    :: Text
  ,pasteDate     :: UTCTime
  ,pasteAuthor   :: Text
  ,pasteLanguage :: Maybe LanguageId
  ,pasteChannel  :: Maybe ChannelId
  ,pastePaste    :: Text
  ,pasteViews    :: Integer
  ,pasteType     :: PasteType
} deriving Show

-- | The type of a paste.
data PasteType
  = NormalPaste
  | AnnotationOf PasteId
  | RevisionOf PasteId
  deriving (Eq,Show)

-- | A paste submission or annotate.
data PasteSubmit = PasteSubmit {
   pasteSubmitId       :: Maybe PasteId
  ,pasteSubmitType     :: PasteType
  ,pasteSubmitTitle    :: Text
  ,pasteSubmitAuthor   :: Text
  ,pasteSubmitLanguage :: Maybe LanguageId
  ,pasteSubmitChannel  :: Maybe ChannelId
  ,pasteSubmitPaste    :: Text
  ,pasteSubmitSpamTrap :: Maybe Text
} deriving Show

instance ToHtml Paste where
  toHtml paste@Paste{..} = toHtml $ pack $ show paste

instance QueryResults Paste where
  convertResults field values = Paste {
      pasteTitle = title
    , pasteAuthor = author
    , pasteLanguage = language
    , pasteChannel = channel
    , pastePaste = content
    , pasteDate = zonedTimeToUTC date
    , pasteId = pid
    , pasteViews = views
    , pasteType = case annotation_of of
      Just pid' -> AnnotationOf pid'
      _ -> case revision_of of
        Just pid' -> RevisionOf pid'
	_ -> NormalPaste
    }
    where (pid,title,content,author,date,views,language,channel,annotation_of,revision_of) =
            convertResults field values

data PasteFormlet = PasteFormlet {
   pfSubmitted :: Bool
 , pfErrors    :: [Text]
 , pfParams    :: Params
 , pfLanguages :: [Language]
 , pfChannels  :: [Channel]
 , pfDefChan   :: Maybe Text
 , pfAnnotatePaste :: Maybe Paste
 , pfEditPaste :: Maybe Paste
 , pfContent :: Maybe Text
}

data ExprFormlet = ExprFormlet {
   efSubmitted :: Bool
 , efParams    :: Params
}

data PastePage = PastePage {
    ppPaste           :: Paste
  , ppChans           :: [Channel]
  , ppLangs           :: [Language]
  , ppHints           :: [Hint]
  , ppAnnotations     :: [Paste]
  , ppRevisions       :: [Paste]
  , ppAnnotationHints :: [[Hint]]
  , ppRevisionsHints  :: [[Hint]]
  , ppRevision        :: Bool
}

data StepsPage = StepsPage {
    spPaste           :: Paste
  , spChans           :: [Channel]
  , spLangs           :: [Language]
  , spHints           :: [Hint]
  , spSteps           :: [Text]
  , spAnnotations     :: [Paste]
  , spAnnotationHints :: [[Hint]]
  , spForm :: Html
}

instance Param Severity where
  render = Escape . toByteString . Utf8.fromString . show
  {-# INLINE render #-}

instance Result Severity where
  convert f = read . convert f
  {-# INLINE convert #-}

-- | A hlint (or like) suggestion.
data Hint = Hint {
   hintType    :: Severity
 , hintContent :: String
}

instance QueryResults Hint where
  convertResults field values = Hint {
      hintType = severity
    , hintContent = content
    }
    where (severity,content) = convertResults field values

data ReportFormlet = ReportFormlet {
   rfSubmitted :: Bool
 , rfParams    :: Params
}

data ReportSubmit = ReportSubmit {
   rsPaste :: PasteId
  ,rsComments :: String
}
