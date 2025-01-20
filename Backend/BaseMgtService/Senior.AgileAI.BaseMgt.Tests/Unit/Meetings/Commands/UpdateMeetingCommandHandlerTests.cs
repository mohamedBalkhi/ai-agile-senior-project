using FluentValidation;
using Moq;
using Senior.AgileAI.BaseMgt.Application.Behaviors;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Contracts.infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Contracts.Services;
using Senior.AgileAI.BaseMgt.Application.DTOs.Meetings;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.CommandHandlers;
using Senior.AgileAI.BaseMgt.Application.Features.Meetings.Commands;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Application.Services;
using Senior.AgileAI.BaseMgt.Application.Validations;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Domain.Enums;
using Xunit;

namespace Senior.AgileAI.BaseMgt.Tests.Unit.Meetings.Commands
{
    public class UpdateMeetingCommandHandlerTests
    {
        private readonly Mock<IUnitOfWork> _mockUnitOfWork;
        private readonly Mock<IProjectAuthorizationHelper> _mockAuthHelper;
        private readonly Mock<IRabbitMQService> _mockRabbitMQ;
        private readonly UpdateMeetingCommandHandler _handler;

        // Fields for meeting and IDs
        private Guid _meetingId;
        private Guid _userId;
        private Guid _projectId;
        private Meeting _meeting;

        private readonly ValidationBehavior<UpdateMeetingCommand, bool> _validationBehavior;
        private readonly IValidator<UpdateMeetingCommand> _validator;

        public UpdateMeetingCommandHandlerTests()
        {
            _mockUnitOfWork = new Mock<IUnitOfWork>();
            _mockAuthHelper = new Mock<IProjectAuthorizationHelper>();
            _mockRabbitMQ = new Mock<IRabbitMQService>();

            var mockTimeZoneService = new Mock<ITimeZoneService>();
            mockTimeZoneService.Setup(x => x.ValidateTimeZone(It.IsAny<string>()))
                .Returns(true);

            _validator = new UpdateMeetingCommandValidator(
                mockTimeZoneService.Object,
                _mockUnitOfWork.Object);

            // Setup validation behavior
            _validationBehavior = new ValidationBehavior<UpdateMeetingCommand, bool>(
                new[] { _validator });

            _handler = new UpdateMeetingCommandHandler(
                _mockUnitOfWork.Object,
                _mockAuthHelper.Object,
                _mockRabbitMQ.Object
            );

            SetupBasicMocks();
        }

        private void SetupBasicMocks()
        {
            // Initialize IDs
            _meetingId = Guid.NewGuid();
            _userId = Guid.NewGuid();
            _projectId = Guid.NewGuid();
            var creatorId = _userId; // The creator is the user

            _meeting = new Meeting
            {
                Id = _meetingId,
                Title = "Original Title",
                Goal = "Original Goal",
                Language = MeetingLanguage.English,
                Type = MeetingType.InPerson,
                StartTime = DateTime.UtcNow.AddDays(1),
                EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
                TimeZoneId = "Asia/Riyadh",
                Location = "Original Location",
                ReminderTime = DateTime.UtcNow.AddHours(12),
                Project_IdProject = _projectId,
                Creator_IdOrganizationMember = creatorId,
                Status = MeetingStatus.Scheduled,
                MeetingMembers = new List<MeetingMember>()
            };

            // Setup UnitOfWork to return this meeting for both GetByIdAsync and GetByIdWithDetailsAsync
            _mockUnitOfWork.Setup(x => x.Meetings.GetByIdAsync(
                It.Is<Guid>(id => id == _meetingId),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(_meeting);

            _mockUnitOfWork.Setup(x => x.Meetings.GetByIdWithDetailsAsync(
                It.Is<Guid>(id => id == _meetingId),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(_meeting);

            // Setup project privilege
            var projectPrivilege = new ProjectPrivilege
            {
                Id = Guid.NewGuid(),
                Project_IdProject = _projectId,
                OrganizationMember_IdOrganizationMember = _userId,
                Meetings = PrivilegeLevel.Write
            };

            _mockUnitOfWork.Setup(x => x.ProjectPrivileges.GetPrivilegeByUserIdAsync(
                It.IsAny<Guid>(),
                It.IsAny<Guid>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(projectPrivilege);

            // Setup authorization helper to return true
            _mockAuthHelper.Setup(x => x.HasProjectPrivilege(
                It.IsAny<Guid>(),
                It.IsAny<Guid>(),
                ProjectAspect.Meetings,
                PrivilegeLevel.Write,
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(true);

            // Setup organization member
            var orgMember = new OrganizationMember
            {
                Id = _userId,
                User = new User 
                { 
                    Id = Guid.NewGuid(),
                    Email = "test@test.com",
                    FUllName = "Test User",
                    IsActive = true,
                    IsTrusted = true,
                    IsAdmin = false,
                    Deactivated = false,
                    Password = "password",
                    BirthDate = new DateOnly(2000, 1, 1),
                },
                IsManager = false,
                HasAdministrativePrivilege = false
            };

            _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByIdAsync(
                It.IsAny<Guid>(),
                It.IsAny<bool>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(orgMember);

            _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByUserId(
                It.IsAny<Guid>(),
                It.IsAny<bool>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(orgMember);

            // Setup meeting members
            _meeting.MeetingMembers = new List<MeetingMember>();
            
            // Setup meeting member repository
            var mockMeetingMemberRepo = new Mock<IMeetingMemberRepository>();
            mockMeetingMemberRepo.Setup(x => x.AddAsync(
                It.IsAny<MeetingMember>(),
                It.IsAny<CancellationToken>()))
                .Callback<MeetingMember, CancellationToken>((mm, ct) => 
                {
                    _meeting.MeetingMembers.Add(mm);
                })
                .Returns(Task.CompletedTask);

            mockMeetingMemberRepo.Setup(x => x.Remove(It.IsAny<MeetingMember>()))
                .Callback<MeetingMember>(mm => 
                {
                    _meeting.MeetingMembers.Remove(mm);
                });

            _mockUnitOfWork.Setup(x => x.MeetingMembers)
                .Returns(mockMeetingMemberRepo.Object);

            // Setup complete async
            _mockUnitOfWork.Setup(x => x.CompleteAsync())
                .ReturnsAsync(1);

            // Setup transaction
            var mockTransaction = new Mock<ITransaction>();
            mockTransaction.Setup(t => t.CommitAsync(It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);
            mockTransaction.Setup(t => t.RollbackAsync(It.IsAny<CancellationToken>()))
                .Returns(Task.CompletedTask);

            _mockUnitOfWork.Setup(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(mockTransaction.Object);

            // Setup notification tokens
            _mockUnitOfWork.Setup(x => x.NotificationTokens.GetTokensByUserId(
                It.IsAny<Guid>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(new List<NotificationToken>());

            // Setup RabbitMQ service
            _mockRabbitMQ.Setup(x => x.PublishNotificationAsync(It.IsAny<NotificationMessage>()))
                .Returns(Task.CompletedTask);
        }

        private async Task<bool> ValidateAndHandle(UpdateMeetingCommand command, CancellationToken cancellationToken)
        {
            // First run the validation
            return await _validationBehavior.Handle(
                command,
                () => _handler.Handle(command, cancellationToken),
                cancellationToken);
        }

        [Fact]
        public async Task Handle_ValidUpdate_ShouldUpdateSuccessfully()
        {
            // Arrange
            var newReminderTime = DateTime.UtcNow.AddHours(20);

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                Title = "Updated Title",
                Goal = "Updated Goal",
                Location = "Updated Location",
                ReminderTime = newReminderTime
            }, _userId);

            // Act
            var result = await ValidateAndHandle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.Equal("Updated Title", _meeting.Title);
            Assert.Equal("Updated Goal", _meeting.Goal);
            Assert.Equal("Updated Location", _meeting.Location);
            Assert.Equal(newReminderTime, _meeting.ReminderTime);
        }

        [Fact]
        public async Task Handle_UnauthorizedUser_ShouldThrowException()
        {
            // Arrange
            // Setup authorization helper to return false
            _mockAuthHelper.Setup(x => x.HasProjectPrivilege(
                _userId,
                _projectId,
                ProjectAspect.Meetings,
                PrivilegeLevel.Write,
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(false);

            // Also, make the meeting creator someone else
            _meeting.Creator_IdOrganizationMember = Guid.NewGuid(); // Not the user

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                Title = "Updated Title"
            }, _userId);

            // Act & Assert
            await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
        }

        [Fact]
        public async Task Handle_InvalidMeetingId_ShouldThrowNotFoundException()
        {
            // Arrange
            var invalidMeetingId = Guid.NewGuid();
            _mockUnitOfWork.Setup(x => x.Meetings.GetByIdWithDetailsAsync(
                It.Is<Guid>(id => id == invalidMeetingId),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync((Meeting)null);

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = invalidMeetingId
            }, _userId);

            // Act & Assert
            await Assert.ThrowsAsync<NotFoundException>(() => 
                _handler.Handle(command, CancellationToken.None));
        }

        [Fact]
        public async Task Handle_AddMembers_ShouldAddMembersSuccessfully()
        {
            // Arrange
            var newMemberId = Guid.NewGuid();

            var orgMember = new OrganizationMember
            {
                Id = newMemberId,
                User = new User
                {
                    Id = Guid.NewGuid(),
                    Email = "newmember@test.com",
                    FUllName = "New Member",
                    IsActive = true,
                    IsTrusted = true,
                    IsAdmin = false,
                    Deactivated = false,
                    Password = "password",
                    BirthDate = new DateOnly(2000, 1, 1),
                },
                IsManager = false,
                HasAdministrativePrivilege = false
            };

            _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByIdAsync(
                It.Is<Guid>(id => id == newMemberId),
                It.IsAny<bool>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(orgMember);

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                AddMembers = new List<Guid> { newMemberId }
            }, _userId);

            // Act
            var result = await ValidateAndHandle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.Contains(_meeting.MeetingMembers, mm => mm.OrganizationMember_IdOrganizationMember == newMemberId);
            _mockRabbitMQ.Verify(x => x.PublishNotificationAsync(
                It.Is<NotificationMessage>(n =>
                    n.Type == NotificationType.Email &&
                    n.Recipient == "newmember@test.com" &&
                    n.Subject.Contains("New Meeting Invitation"))),
                Times.Once);
        }

        [Fact]
        public async Task Handle_RemoveMembers_ShouldRemoveMembersSuccessfully()
        {
            // Arrange
            var memberId = Guid.NewGuid();
            var orgMember = new OrganizationMember
            {
                Id = memberId,
                User = new User
                {
                    Id = Guid.NewGuid(),
                    Email = "test@test.com",
                    FUllName = "Test User",
                    IsActive = true,
                    IsTrusted = true,
                    IsAdmin = false,
                    Deactivated = false,
                    Password = "password",
                    BirthDate = new DateOnly(2000, 1, 1),
                },
                IsManager = false,
                HasAdministrativePrivilege = false
            };

            var existingMeetingMember = new MeetingMember
            {
                Meeting_IdMeeting = _meetingId,
                OrganizationMember_IdOrganizationMember = memberId,
                OrganizationMember = orgMember
            };
            _meeting.MeetingMembers.Add(existingMeetingMember);

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                RemoveMembers = new List<Guid> { memberId }
            }, _userId);

            // Act
            var result = await ValidateAndHandle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.DoesNotContain(_meeting.MeetingMembers, mm => 
                mm.OrganizationMember_IdOrganizationMember == memberId);
        }

        [Fact]
        public async Task Handle_RemoveNonExistentMember_ShouldThrowValidationException()
        {
            // Arrange
            var nonExistentMemberId = Guid.NewGuid();
            
            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                RemoveMembers = new List<Guid> { nonExistentMemberId }
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
            Assert.Contains("One or more members to remove are not part of the meeting", 
                exception.Message);
        }

        [Fact]
        public async Task Handle_UpdateRecurringPattern_ShouldUpdateSuccessfully()
        {
            // Arrange
            // First, the meeting should have an existing recurring pattern
            _meeting.RecurringPattern = new RecurringMeetingPattern
            {
                Id = Guid.NewGuid(),
                Meeting_IdMeeting = _meetingId,
                RecurrenceType = RecurrenceType.Daily,
                Interval = 1,
                RecurringEndDate = DateTime.UtcNow.AddMonths(1),
                DaysOfWeek = null
            };

            var newRecurringPattern = new RecurringMeetingPatternDTO
            {
                RecurrenceType = RecurrenceType.Weekly,
                Interval = 2,
                RecurringEndDate = DateTime.UtcNow.AddMonths(2),
                DaysOfWeek = DaysOfWeek.Monday | DaysOfWeek.Wednesday
            };

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                RecurringPattern = newRecurringPattern
            }, _userId);

            // Act
            var result = await ValidateAndHandle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.Equal(RecurrenceType.Weekly, _meeting.RecurringPattern.RecurrenceType);
            Assert.Equal(2, _meeting.RecurringPattern.Interval);
            Assert.Equal(newRecurringPattern.RecurringEndDate, _meeting.RecurringPattern.RecurringEndDate);
            Assert.Equal(newRecurringPattern.DaysOfWeek, _meeting.RecurringPattern.DaysOfWeek);
        }

        [Fact]
        public async Task Handle_ExceptionDuringUpdate_ShouldRollbackTransaction()
        {
            // Arrange
            _mockUnitOfWork.Setup(x => x.CompleteAsync())
                .ThrowsAsync(new Exception("Database error"));

            var mockTransaction = new Mock<ITransaction>();
            _mockUnitOfWork.Setup(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()))
                .ReturnsAsync(mockTransaction.Object);

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                Title = "Updated Title"
            }, _userId);

            // Act & Assert
            await Assert.ThrowsAsync<Exception>(() =>
                ValidateAndHandle(command, CancellationToken.None));

            // Verify that the transaction was rolled back
            mockTransaction.Verify(x => x.RollbackAsync(It.IsAny<CancellationToken>()), Times.Once);
        }

        [Fact]
        public async Task Handle_ExceptionDuringNotification_ShouldNotFailUpdate()
        {
            // Arrange
            var memberId = Guid.NewGuid();
            var orgMember = new OrganizationMember
            {
                Id = memberId,
                User = new User
                {
                    Id = Guid.NewGuid(),
                    Email = "test@test.com",
                    FUllName = "Test User",
                    IsActive = true,
                    IsTrusted = true,
                    IsAdmin = false,
                    Deactivated = false,
                    Password = "password",
                    BirthDate = new DateOnly(2000, 1, 1),
                },
                IsManager = false,
                HasAdministrativePrivilege = false
            };

            _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByIdAsync(
                It.Is<Guid>(id => id == memberId),
                It.IsAny<bool>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync(orgMember);

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                AddMembers = new List<Guid> { memberId }
            }, _userId);

            _mockRabbitMQ.Setup(x => x.PublishNotificationAsync(It.IsAny<NotificationMessage>()))
                .ThrowsAsync(new Exception("Notification service failed"));

            // Act
            var result = await ValidateAndHandle(command, CancellationToken.None);

            // Assert
            Assert.True(result);
            Assert.Contains(_meeting.MeetingMembers, mm => 
                mm.OrganizationMember_IdOrganizationMember == memberId);
        }

        [Fact]
        public async Task Handle_UpdateStartTimeOfStartedMeeting_ShouldThrowValidationException()
        {
            // Arrange
            _meeting.Status = MeetingStatus.InProgress;
            // Set up recurring pattern to make the meeting recurring
            _meeting.RecurringPattern = new RecurringMeetingPattern
            {
                Id = Guid.NewGuid(),
                Meeting_IdMeeting = _meetingId,
                RecurrenceType = RecurrenceType.Daily,
                Interval = 1,
                RecurringEndDate = DateTime.UtcNow.AddMonths(1)
            };

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                StartTime = DateTime.UtcNow.AddDays(2)
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
            Assert.Contains("Cannot update start time of a recurring meeting that has already started", 
                exception.Message);
        }

        [Fact]
        public async Task Handle_UpdateWithExcessivelyLongTitle_ShouldThrowValidationException()
        {
            // Arrange
            var longTitle = new string('A', 201); // 201 characters
            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                Title = longTitle
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
            Assert.Contains("Title cannot exceed 200 characters", exception.Message);
        }

        [Fact]
        public async Task Handle_UpdateStartTimeAfterEndTime_ShouldThrowValidationException()
        {
            // Arrange
            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                StartTime = DateTime.UtcNow.AddHours(3),
                EndTime = DateTime.UtcNow.AddHours(2) // End time before start time
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
            Assert.Contains("End time must be after start time", exception.Message);
        }

        [Fact]
        public async Task Handle_UpdateWithPastReminderTime_ShouldThrowValidationException()
        {
            // Arrange
            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                ReminderTime = DateTime.UtcNow.AddHours(-1)
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
            Assert.Contains("Reminder time must be in the future", exception.Message);
        }

        [Fact]
        public async Task Handle_UpdateRecurringPatternWithInvalidInterval_ShouldThrowValidationException()
        {
            // Arrange
            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                RecurringPattern = new RecurringMeetingPatternDTO
                {
                    RecurrenceType = RecurrenceType.Daily,
                    Interval = 0, // Invalid interval
                    RecurringEndDate = DateTime.UtcNow.AddMonths(1)
                }
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                ValidateAndHandle(command, CancellationToken.None));
            Assert.Contains("Interval must be greater than 0", exception.Message);
        }

        [Fact]
        public async Task Handle_UpdateWithInvalidTimeZone_ShouldThrowValidationException()
        {
            // Arrange
            var mockTimeZoneService = new Mock<ITimeZoneService>();
            mockTimeZoneService.Setup(x => x.ValidateTimeZone(It.IsAny<string>()))
                .Returns(false);

            var validator = new UpdateMeetingCommandValidator(
                mockTimeZoneService.Object,
                _mockUnitOfWork.Object);

            var validationBehavior = new ValidationBehavior<UpdateMeetingCommand, bool>(
                new[] { validator });

            var command = new UpdateMeetingCommand(new UpdateMeetingDTO
            {
                MeetingId = _meetingId,
                TimeZone = "Invalid/TimeZone"
            }, _userId);

            // Act & Assert
            var exception = await Assert.ThrowsAsync<ValidationException>(() =>
                validationBehavior.Handle(
                    command,
                    () => _handler.Handle(command, CancellationToken.None),
                    CancellationToken.None));
            Assert.Contains("Invalid timezone", exception.Message);
        }
    }
}
