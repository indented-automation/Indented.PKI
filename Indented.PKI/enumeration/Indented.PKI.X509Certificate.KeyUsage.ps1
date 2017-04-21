Add-Type -TypeDefinition '
    using System;

    namespace Indented.PKI.X509Certificate
    {
        [Flags]
        public enum KeyUsage : int
        {
            CERT_ENCIPHER_ONLY_KEY_USAGE      = 1,
            CERT_OFFLINE_CRL_SIGN_KEY_USAGE   = 2,
            CERT_KEY_CERT_SIGN_KEY_USAGE      = 4,
            CERT_KEY_AGREEMENT_KEY_USAGE      = 8,
            CERT_DATA_ENCIPHERMENT_KEY_USAGE  = 16,
            CERT_KEY_ENCIPHERMENT_KEY_USAGE   = 32,
            CERT_NON_REPUDIATION_KEY_USAGE    = 64,
            CERT_DIGITAL_SIGNATURE_KEY_USAGE  = 128,
            CERT_DECIPHER_ONLY_KEY_USAGE      = 32768
        }
    }
'