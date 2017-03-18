namespace Indented.PKI.CAResponse
{
    public class Disposition : int
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