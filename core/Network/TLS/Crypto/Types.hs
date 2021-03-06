-- |
-- Module      : Network.TLS.Crypto.Types
-- License     : BSD-style
-- Maintainer  : Kazu Yamamoto <kazu@iij.ad.jp>
-- Stability   : experimental
-- Portability : unknown
--
module Network.TLS.Crypto.Types where

data Group = P256 | P384 | P521 | X25519 | X448
           | FFDHE2048 | FFDHE3072 | FFDHE4096 | FFDHE6144 | FFDHE8192
           deriving (Eq, Show)

availableFFGroups :: [Group]
availableFFGroups = [FFDHE2048,FFDHE3072,FFDHE4096,FFDHE6144,FFDHE8192]

availableECGroups :: [Group]
availableECGroups = [P256,P384,P521,X25519,X448]

availableGroups :: [Group]
availableGroups = availableECGroups ++ availableFFGroups

-- Digital signature algorithm, in close relation to public/private key types
-- and cipher key exchange.
data DigitalSignatureAlg = RSA | DSS | ECDSA | Ed25519 | Ed448
                           deriving (Show, Eq)
