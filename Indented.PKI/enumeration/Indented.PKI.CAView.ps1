Add-Type -TypeDefinition '
    namespace Indented.PKI.CAView
    {
        public enum DataType : int
        {
            PROPTYPE_BINARY = 1,
            PROPTYPE_DATE   = 2,
            PROPTYPE_LONG   = 3,
            PROPTYPE_STRING = 4
        }

        public enum RestrictionIndex : int
        {
            CV_COLUMN_QUEUE_DEFAULT      = -1,
            CV_COLUMN_LOG_DEFAULT        = -2,
            CV_COLUMN_LOG_FAILED_DEFAULT = -3
        }

        public enum ResultColumn : int
        {
            CVRC_COLUMN_SCHEMA = 0,
            CVRC_COLUMN_RESULT = 1,
            CVRC_COLUMN_VALUE  = 2
        }

        public enum Seek : int
        {
            CVR_SEEK_EQ = 1,
            CVR_SEEK_LT = 2,
            CVR_SEEK_LE = 4,
            CVR_SEEK_GE = 8,
            CVR_SEEK_GT = 16           
        }

        public enum Sort : int
        {
            CVR_SORT_NONE    = 0,
            CVR_SORT_ASCEND  = 1,
            CVR_SORT_DESCEND = 2
        }

        public enum Table : int
        {
            CVRC_TABLE_REQCERT    = 0,
            CVRC_TABLE_EXTENSIONS = 12288,
            CVRC_TABLE_ATTRIBUTES = 16384,
            CVRC_TABLE_CRL        = 20480        
        }
    }
'