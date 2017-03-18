namespace Indented.PKI.CertificateRequest
{
    public enum Disposition : int
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
}