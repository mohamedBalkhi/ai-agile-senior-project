using System.Text.Json;
using MediatR;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Senior.AgileAI.BaseMgt.Application.Behaviors;

public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : notnull
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(
        TRequest request, 
        RequestHandlerDelegate<TResponse> next, 
        CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        var requestGuid = Guid.NewGuid().ToString();

        try
        {
            // Sanitize and serialize the request
            var sanitizedRequest = SanitizeRequest(request);
            
            _logger.LogInformation(
                "Handling {RequestName} [{RequestGuid}]. Request Data: {RequestData}",
                requestName,
                requestGuid,
                sanitizedRequest);

            var sw = System.Diagnostics.Stopwatch.StartNew();
            var response = await next();
            sw.Stop();

            // Sanitize and serialize the response
            var sanitizedResponse = SanitizeResponse(response);

            _logger.LogInformation(
                "Handled {RequestName} [{RequestGuid}] in {ElapsedMilliseconds}ms. Response Data: {ResponseData}",
                requestName,
                requestGuid,
                sw.ElapsedMilliseconds,
                sanitizedResponse);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Error handling {RequestName} [{RequestGuid}]. Error: {Error}",
                requestName,
                requestGuid,
                ex.Message);
            throw;
        }
    }

    private string SanitizeRequest(TRequest request)
    {
        try
        {
            var sanitized = new Dictionary<string, object>();
            var properties = request.GetType().GetProperties();

            foreach (var prop in properties)
            {
                var value = prop.GetValue(request);
                
                // Skip null values
                if (value == null) continue;

                // Handle sensitive data
                if (IsSensitiveProperty(prop.Name))
                {
                    sanitized[prop.Name] = "***REDACTED***";
                    continue;
                }

                // Handle file properties
                if (typeof(IFormFile).IsAssignableFrom(prop.PropertyType))
                {
                    var file = value as IFormFile;
                    sanitized[prop.Name] = new
                    {
                        FileName = file?.FileName,
                        Length = file?.Length,
                        ContentType = file?.ContentType
                    };
                    continue;
                }

                sanitized[prop.Name] = value;
            }

            return JsonSerializer.Serialize(sanitized, new JsonSerializerOptions 
            { 
                WriteIndented = true,
                ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles
            });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error sanitizing request");
            return "[Error sanitizing request]";
        }
    }

    private string SanitizeResponse(TResponse? response)
    {
        try
        {
            if (response == null) return "null";

            return JsonSerializer.Serialize(response, new JsonSerializerOptions 
            { 
                WriteIndented = true,
                ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles
            });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Error sanitizing response");
            return "[Error sanitizing response]";
        }
    }

    private bool IsSensitiveProperty(string propertyName)
    {
        var sensitiveProps = new[]
        {
            "password",
            "token",
            "secret",
            "credential",
            "key"
        };

        return sensitiveProps.Any(p => 
            propertyName.ToLower().Contains(p.ToLower()));
    }
} 