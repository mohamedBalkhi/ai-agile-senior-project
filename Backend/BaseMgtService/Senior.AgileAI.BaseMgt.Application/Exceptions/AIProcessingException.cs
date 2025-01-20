namespace Senior.AgileAI.BaseMgt.Application.Exceptions;

public class AIProcessingException : ApplicationException
{
    public AIProcessingException(string message) : base(message)
    {
    }

    public AIProcessingException(string message, Exception innerException) 
        : base(message, innerException)
    {
    }
}
