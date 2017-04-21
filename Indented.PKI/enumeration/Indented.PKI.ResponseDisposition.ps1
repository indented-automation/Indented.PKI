Add-Type -TypeDefinition '
    namespace Indented.PKI.ResponseDisposition
    {
        public enum ResponseDisposition : int
        {
            Incomplete      = 0,
            Error           = 1,
            Denied          = 2,
            Issued          = 3,
            IssuedOutOfBand = 4,
            UnderSubmission = 5,
            Revoked         = 6
        }
    }
'