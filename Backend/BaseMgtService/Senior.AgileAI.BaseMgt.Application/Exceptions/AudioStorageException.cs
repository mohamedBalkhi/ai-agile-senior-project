public class AudioStorageException : Exception
{
    public AudioStorageException(string message) : base(message)
    {
    }

    public AudioStorageException(string message, Exception innerException) 
        : base(message, innerException)
    {
    }
} 