using Amazon.S3;
using System.Net;

namespace Senior.AgileAI.BaseMgt.Infrastructure.Extensions;

public static class AmazonS3ExceptionExtensions
{
    public static bool IsTransient(this AmazonS3Exception ex)
    {
        return ex.StatusCode == HttpStatusCode.RequestTimeout ||
               ex.StatusCode == HttpStatusCode.InternalServerError ||
               ex.StatusCode == HttpStatusCode.ServiceUnavailable ||
               ex.StatusCode == HttpStatusCode.BadGateway;
    }
} 