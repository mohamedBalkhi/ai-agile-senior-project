using Microsoft.AspNetCore.Mvc;
using NotificationService.Models;
using NotificationService.Services.Interfaces;

namespace NotificationService.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class EmailController : ControllerBase
    {
        private readonly IEmailNotificationService _emailNotificationService;

        public EmailController(IEmailNotificationService emailNotificationService)
        {
            _emailNotificationService = emailNotificationService;
        }

        [HttpPost("send")]
        public async Task<IActionResult> SendEmail([FromBody] NotificationMessage message)
        {
            if (message == null || string.IsNullOrEmpty(message.Recipient) || string.IsNullOrEmpty(message.Subject) || string.IsNullOrEmpty(message.Body))
            {
                return BadRequest("Invalid email message.");
            }

            try
            {
                await _emailNotificationService.SendEmailAsync(message);
                return Ok("Email sent successfully.");
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Internal server error: {ex.Message}");
            }
        }
    }
}
