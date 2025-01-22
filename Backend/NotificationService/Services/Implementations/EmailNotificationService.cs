using NotificationService.Models;
using NotificationService.Services.Interfaces;
using MailKit.Net.Smtp;
using MimeKit;
using Polly;
using Polly.Retry;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;

namespace NotificationService.Services.Implementations
{
    public class EmailNotificationService : IEmailNotificationService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailNotificationService> _logger;

        // Limit concurrency to 1 (example usage)
        private static readonly SemaphoreSlim _throttler = new SemaphoreSlim(1, 1);

        // The RetryPolicy for SmtpProtocolExceptions only
        private static readonly AsyncRetryPolicy<bool> RetryPolicy = Policy<bool>
            .Handle<SmtpProtocolException>()
            .WaitAndRetryAsync(
                retryCount: 3,
                sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                onRetry: (outcome, timeSpan, retryNumber, context) =>
                {
                    // "outcome" is a DelegateResult<bool>, which can have an Exception if the call threw one
                    var ex = outcome.Exception;

                    // If you stored a logger in the context, retrieve and use it
                    if (context.TryGetValue("logger", out var loggerObj) && loggerObj is ILogger logger)
                    {
                        if (ex != null)
                        {
                            logger.LogWarning($"Retry {retryNumber} after {timeSpan.TotalSeconds} seconds due to: {ex.Message}");
                        }
                        else
                        {
                            logger.LogWarning($"Retry {retryNumber} after {timeSpan.TotalSeconds} seconds (no exception thrown).");
                        }
                    }
                }
            );

        public EmailNotificationService(IConfiguration configuration, ILogger<EmailNotificationService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(NotificationMessage message)
        {
            // Ensure only one message sending process at a time
            await _throttler.WaitAsync();
            
            try
            {
                // Context to pass the logger to onRetry
                var context = new Context();
                context["logger"] = _logger;

                // Execute with policy
                var result = await RetryPolicy.ExecuteAndCaptureAsync(async (ctx) =>
                {
                    try
                    {
                        await SendEmailInternalAsync(message);
                        return true;
                    }
                    catch (SmtpProtocolException ex) when (ex.Message.Contains("Too many login attempts"))
                    {
                        _logger.LogError(ex, $"SMTP rate limit exceeded for {message.Recipient}. Will retry after backoff.");
                        throw;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"Error sending email to {message.Recipient}");
                        throw;
                    }
                }, context);

                // Evaluate the outcome
                if (result.Result)
                {
                    _logger.LogInformation($"Email sent successfully to {message.Recipient}");
                }
                else if (result.FinalException != null)
                {
                    _logger.LogError(result.FinalException, $"Failed to send email to {message.Recipient} after all retries");
                    throw result.FinalException;
                }
            }
            finally
            {
                _throttler.Release();
            }
        }

        private async Task SendEmailInternalAsync(NotificationMessage message)
        {
            var emailSettings = _configuration.GetSection("EmailSettings");

            var email = new MimeMessage();
            email.From.Add(new MailboxAddress("Your App", emailSettings["FromEmail"]));
            email.To.Add(MailboxAddress.Parse(message.Recipient));
            email.Subject = message.Subject;

            email.Body = new TextPart("plain")
            {
                Text = message.Body
            };

            using var smtpClient = new SmtpClient();
            // Accept all SSL certificates (for dev/test only; not recommended for production)
            smtpClient.ServerCertificateValidationCallback = (s, c, h, e) => true;

            // Connect and authenticate
            await smtpClient.ConnectAsync(
                emailSettings["SmtpServer"]!,
                int.Parse(emailSettings["Port"]!),
                MailKit.Security.SecureSocketOptions.Auto);

            await smtpClient.AuthenticateAsync(
                emailSettings["UserName"]!, 
                emailSettings["Password"]!);

            // Send message
            await smtpClient.SendAsync(email);
            await smtpClient.DisconnectAsync(true);
        }
    }
}
