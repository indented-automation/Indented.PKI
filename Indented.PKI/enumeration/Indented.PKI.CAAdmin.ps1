Add-Type -TypeDefinition '
    namespace Indented.PKI.CAAdmin
    {
        public enum DeleteRowFlag : int
        {
            NONE                     = 0,
            CDR_EXPIRED              = 1,
            CDR_REQUEST_LAST_CHANGED = 2
        }

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