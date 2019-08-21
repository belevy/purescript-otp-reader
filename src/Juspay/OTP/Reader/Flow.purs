module Juspay.OTP.Reader.Flow (
    module Juspay.OTP.Reader,
    getGodelOtpRules,
    getSmsReadPermission,
    requestSmsReadPermission,
    smsPoller,
    OtpListener,
    getOtpListener
  ) where

import Prelude

import Effect (Effect)
import Effect.Aff (Aff, Milliseconds)
import Effect.Class (liftEffect)
import Foreign (F)
import Juspay.OTP.Reader (Otp(..), OtpError(..), OtpRule(..), Sms(..), SmsReader(..), clipboard, extractOtp, getName, smsReceiver)
import Juspay.OTP.Reader as O
import Presto.Core.Types.Language.Flow (Flow, doAff)

doAff' :: forall a. Aff a -> Flow a
doAff' aff = doAff aff

doEff' :: forall a. Effect a -> Flow a
doEff' eff = doAff' $ liftEffect eff

-- | Flow version of `getGodelOtpRules` from `Juspay.OTP.Reader`
-- | Gets bank OTP rules from Godel's config.
getGodelOtpRules :: String -> Flow (F (Array OtpRule))
getGodelOtpRules = doEff' <<< O.getGodelOtpRules

-- | Flow version of smsPoller from Juspay.OTP.Reader
-- | Capture incoming SMSs by polling the SMS inbox at regular intervals. The
-- | first argument specifies the earliest time from which SMSs should be read
-- | (eg: session start time or time just before OTP trigger). The second
-- | argument specifies the frequency with which the poller should run (suggested
-- | frequency: 2 seconds). This requires SMS permission to work
smsPoller :: Milliseconds -> Milliseconds -> Flow SmsReader
smsPoller startTime frequency = do
  doEff' $ O.smsPoller startTime frequency

-- | Flow version of `getSmsReadPermission` from Juspay.OTP.Reader
-- | Checks if Android SMS Read permission has been granted
getSmsReadPermission :: Flow Boolean
getSmsReadPermission = doAff' $ liftEffect O.getSmsReadPermission

-- | Flow version of `getSmsReadPermission` from Juspay.OTP.Reader
-- | Requests Android SMS Read permission from the user
requestSmsReadPermission :: Flow Boolean
requestSmsReadPermission = doAff' O.requestSmsReadPermission

type OtpListener = {
  getNextOtp :: Flow Otp,
  setOtpRules :: Array OtpRule -> Flow Unit
}

-- | Flow version of `getSmsReadPermission` from Juspay.OTP.Reader
-- | Takes an array of `SmsReader`s and returns functions to get OTPs. It uses the
-- | supplied `SmsReader`s  by running them in parallel to capture any incoming
-- | SMSs and attempts to extract an OTP from them using given OTP rules. Check
-- | the `OtpListener` type for more info on how to get OTPs and set OTP rules.
getOtpListener :: Array SmsReader -> Flow OtpListener
getOtpListener readers = do
  listener <- doAff' $ O.getOtpListener readers
  pure {
    getNextOtp: doAff' listener.getNextOtp,
    setOtpRules: doAff' <<< listener.setOtpRules
  }