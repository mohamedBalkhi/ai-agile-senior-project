using NotificationService.Models;
using NotificationService.Services.Interfaces;
using MailKit.Net.Smtp;
using MimeKit;

namespace NotificationService.Services.Implementations
{
    public class EmailNotificationService : IEmailNotificationService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailNotificationService> _logger;

        public EmailNotificationService(IConfiguration configuration, ILogger<EmailNotificationService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(NotificationMessage message)
        {
            try
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
                smtpClient.ServerCertificateValidationCallback = (s, c, h, e) => true;
                await smtpClient.ConnectAsync(emailSettings["SmtpServer"]!, int.Parse(emailSettings["Port"]!), MailKit.Security.SecureSocketOptions.Auto);
                await smtpClient.AuthenticateAsync(emailSettings["UserName"]!, emailSettings["Password"]!);
                await smtpClient.SendAsync(email);
                await smtpClient.DisconnectAsync(true);

                _logger.LogInformation($"Email sent successfully to {message.Recipient}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending email to {message.Recipient}");
                throw;
            }
        }
    }
}
