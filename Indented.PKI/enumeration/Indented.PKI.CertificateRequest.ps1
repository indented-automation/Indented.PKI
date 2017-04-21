Add-Type -TypeDefinition '
    namespace Indented.PKI.CA
    {
        public enum CertificateRequestDisposition : int
        {
            Active      = 8,
            Pending     = 9,
            Foreign     = 12,
            CACert      = 15,
            CACertChain = 16,
            KRACert     = 17,
            Issued      = 20,
            Revoked     = 21,
            Error       = 30,
            Denied      = 31
        }

        public enum CertificateRequestEncoding : int
        {
            CR_OUT_BASE64HEADER = 0,
            CR_OUT_BASE64       = 1,
            CR_OUT_BINARY       = 2
        }

        public enum CertificateRequestRequestType : int
        {
            CR_IN_FORMATANY    = 0,
            CR_IN_PKCS10       = 256,
            CR_IN_KEYGEN       = 512,
            CR_IN_PKCS7        = 768,
            CR_IN_CMC          = 1024,
            CR_IN_RPC          = 131072,
            CR_IN_FULLRESPONSE = 262144,
            CR_IN_CRLS         = 524288
        }
    }
'