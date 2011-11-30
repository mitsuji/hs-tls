module Tests.Connection
	( newPairContext
	, arbitraryPairParams
	) where

import Test.QuickCheck
import Tests.Certificate
import Tests.PubKey
import Tests.PipeChan
import Network.TLS
import Network.TLS.Core
import Network.TLS.Cipher
import Network.TLS.Crypto
import Control.Concurrent

import qualified Crypto.Random.AESCtr as RNG
import qualified Data.ByteString as B

idCipher :: Cipher
idCipher = Cipher
	{ cipherID   = 0xff12
	, cipherName = "rsa-id-const"
	, cipherBulk = Bulk
		{ bulkName      = "id"
		, bulkKeySize   = 16
		, bulkIVSize    = 16
		, bulkBlockSize = 16
		, bulkF         = BulkBlockF (\k iv m -> m) (\k iv m -> m)
		}
	, cipherHash = Hash
		{ hashName = "const-hash"
		, hashSize = 16
		, hashF    = (\_ -> B.replicate 16 1)
		}
	, cipherKeyExchange = CipherKeyExchange_RSA
	, cipherMinVer      = Nothing
	}

supportedCiphers :: [Cipher]
supportedCiphers = [idCipher]

supportedVersions :: [Version]
supportedVersions = [SSL3,TLS10,TLS11,TLS12]

arbitraryPairParams = do
	let (pubKey, privKey) = getGlobalRSAPair
	servCert          <- arbitraryX509WithPublicKey pubKey
	allowedVersions   <- arbitraryVersions
	connectVersion    <- elements supportedVersions `suchThat` (\c -> c `elem` allowedVersions)
	serverCiphers     <- arbitraryCiphers
	clientCiphers     <- oneof [arbitraryCiphers] `suchThat` (\cs -> or [x `elem` serverCiphers | x <- cs])
	secNeg            <- arbitrary

	let serverState = defaultParams
		{ pAllowedVersions        = allowedVersions
		, pCiphers                = serverCiphers
		, pCertificates           = [(servCert, Just $ PrivRSA privKey)]
		, pUseSecureRenegotiation = secNeg
		}
	let clientState = defaultParams
		{ pConnectVersion         = connectVersion
		, pAllowedVersions        = allowedVersions
		, pCiphers                = clientCiphers
		, pUseSecureRenegotiation = secNeg
		}
	return (clientState, serverState)
	where
		arbitraryVersions :: Gen [Version]
		arbitraryVersions = resize (length supportedVersions + 1) $ listOf1 (elements supportedVersions)
		arbitraryCiphers  = resize (length supportedCiphers + 1) $ listOf1 (elements supportedCiphers)

newPairContext pipe (cParams, sParams) = do
	let noFlush = return ()

	cRNG <- RNG.makeSystem
	sRNG <- RNG.makeSystem

	cCtx' <- clientWith cParams cRNG () noFlush (writePipeA pipe) (readPipeA pipe)
	sCtx' <- serverWith sParams sRNG () noFlush (writePipeB pipe) (readPipeB pipe)

	return (cCtx', sCtx')