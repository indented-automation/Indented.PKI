namespace Indented.PKI.CertificateRequest
{
    public enum RequestType : int
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