using FluentValidation;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;
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

namespace Senior.AgileAI.BaseMgt.Tests.Unit.Meetings.Commands;

public class CreateMeetingCommandHandlerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IRecurringMeetingService> _mockRecurringService;
    private readonly Mock<IAudioStorageService> _mockAudioStorage;
    private readonly Mock<IProjectAuthorizationHelper> _mockAuthHelper;
    private readonly Mock<IRabbitMQService> _mockRabbitMQ;
    private readonly Mock<ILogger<CreateMeetingCommandHandler>> _mockLogger;
    private readonly Mock<ITransaction> _mockTransaction;
    private readonly Mock<ITimeZoneService> _mockTimeZoneService;
    private readonly CreateMeetingCommandHandler _handler;
    private readonly ValidationBehavior<CreateMeetingCommand, Guid> _validationBehavior;
private readonly IValidator<CreateMeetingCommand> _validator;

    public CreateMeetingCommandHandlerTests()
    {
        _mockUnitOfWork = new Mock<IUnitOfWork>();
        _mockRecurringService = new Mock<IRecurringMeetingService>();
        _mockAudioStorage = new Mock<IAudioStorageService>();
        _mockAuthHelper = new Mock<IProjectAuthorizationHelper>();
        _mockRabbitMQ = new Mock<IRabbitMQService>();
        _mockLogger = new Mock<ILogger<CreateMeetingCommandHandler>>();
        _mockTransaction = new Mock<ITransaction>();
        _mockTimeZoneService = new Mock<ITimeZoneService>();
        _mockTimeZoneService.Setup(x => x.ValidateTimeZone(It.IsAny<string>()))
            .Returns(true);

        _validator = new CreateMeetingCommandValidator(
                _mockTimeZoneService.Object,
            _mockUnitOfWork.Object,
            _mockAudioStorage.Object);

    // Setup validation behavior
    _validationBehavior = new ValidationBehavior<CreateMeetingCommand, Guid>(
        new[] { _validator });

        _handler = new CreateMeetingCommandHandler(
            _mockUnitOfWork.Object,
            _mockRecurringService.Object,
            _mockAudioStorage.Object,
            _mockAuthHelper.Object,
            _mockRabbitMQ.Object,
            _mockLogger.Object);

        SetupBasicMocks();
    }

    private void SetupBasicMocks()
    {
        // Setup project
        var project = new Project
        {
            Id = Guid.NewGuid(),
            Name = "Test Project",
            Status = true,
            Organization_IdOrganization = Guid.NewGuid(),
            ProjectManager_IdProjectManager = Guid.NewGuid(),
            Description = "Test Description"
        };

        // Setup both overloads of GetByIdAsync
        _mockUnitOfWork.Setup(x => x.Projects.GetByIdAsync(
            It.IsAny<Guid>(),
            It.IsAny<CancellationToken>(),
            It.IsAny<bool>()))
            .ReturnsAsync(project);

   

        // Setup organization member
        var creator = new OrganizationMember
        {
            Id = Guid.NewGuid(),
            User = new User 
            { 
                Email = "creator@test.com",
                FUllName = "Test Creator",
                Password = "test",
                BirthDate = new DateOnly(2000,1,1),
                IsActive = true,
                IsTrusted = true,
                IsAdmin = false,
                Deactivated = false,
                Country_IdCountry = Guid.NewGuid()
            },
            Organization_IdOrganization = project.Organization_IdOrganization,
            IsManager = true,
            HasAdministrativePrivilege = true
        };

        // _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByUserId(
        //     It.IsAny<Guid>(),
        //     It.IsAny<CancellationToken>()))
        //     .ReturnsAsync(creator);

        _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByUserId(
            It.IsAny<Guid>(),
            It.IsAny<bool>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(creator);

        // Setup project privilege
        var projectPrivilege = new ProjectPrivilege
        {
            Id = Guid.NewGuid(),
            Project_IdProject = project.Id,
            OrganizationMember_IdOrganizationMember = creator.Id,
            Meetings = PrivilegeLevel.Write
        };

        _mockUnitOfWork.Setup(x => x.ProjectPrivileges.GetPrivilegeByUserIdAsync(
            It.IsAny<Guid>(),
            It.IsAny<Guid>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(projectPrivilege);

        // Setup auth helper
        _mockAuthHelper.Setup(x => x.HasProjectPrivilege(
            It.IsAny<Guid>(),
            It.IsAny<Guid>(),
            ProjectAspect.Meetings,
            PrivilegeLevel.Write,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        // Setup meeting repository add
        // Setup meeting repository add
var mockMeetingRepo = new Mock<IMeetingRepository>();
mockMeetingRepo.Setup(x => x.AddAsync(
    It.IsAny<Meeting>(),
    It.IsAny<CancellationToken>()))
    .Returns((Meeting m, CancellationToken ct) =>
    {
        m.Id = Guid.NewGuid(); // Assign a new GUID
        return Task.FromResult(m);
    });


     var member = new OrganizationMember
        {
            Id = Guid.NewGuid(),
            IsManager = false,
            HasAdministrativePrivilege = false,
            Organization_IdOrganization = Guid.NewGuid(),
            User = new User 
            { 
                Email = "member@test.com",
                FUllName = "Test Member",
                Password = "test",
                BirthDate = new DateOnly(2000,1,1),
                IsActive = true,
                IsTrusted = true,
                IsAdmin = false,
                Deactivated = false,
                Country_IdCountry = Guid.NewGuid()
            }
        };

        _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByIdAsync(
            It.IsAny<Guid>(), It.IsAny<bool>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(member);


        // Setup meeting member repository 
        var mockMeetingMemberRepo = new Mock<IMeetingMemberRepository>();
        mockMeetingMemberRepo.Setup(x => x.AddAsync(
            It.IsAny<MeetingMember>(),
            It.IsAny<CancellationToken>()))
            .Returns((MeetingMember mm, CancellationToken ct) => Task.FromResult(mm));

        // Setup recurring pattern repository
        var mockRecurringPatternRepo = new Mock<IRecurringMeetingPatternRepository>();
        mockRecurringPatternRepo.Setup(x => x.AddAsync(
            It.IsAny<RecurringMeetingPattern>(),
            It.IsAny<CancellationToken>()))
            .Returns((RecurringMeetingPattern rp, CancellationToken ct) => Task.FromResult(rp));

        // Setup repositories in UnitOfWork
        _mockUnitOfWork.Setup(x => x.Meetings).Returns(mockMeetingRepo.Object);
        _mockUnitOfWork.Setup(x => x.MeetingMembers).Returns(mockMeetingMemberRepo.Object);
        _mockUnitOfWork.Setup(x => x.RecurringMeetingPatterns).Returns(mockRecurringPatternRepo.Object);

        // Setup complete async
        _mockUnitOfWork.Setup(x => x.CompleteAsync())
            .ReturnsAsync(1);

        // Setup validation
        mockMeetingRepo.Setup(x => x.ValidateMeetingTimeAsync(
            It.IsAny<Guid>(),
            It.IsAny<DateTime>(),
            It.IsAny<DateTime>(),
            It.IsAny<Guid?>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

            

        // Setup transaction
        _mockTransaction.Setup(t => t.CommitAsync(It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        _mockTransaction.Setup(t => t.RollbackAsync(It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        _mockUnitOfWork.Setup(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(_mockTransaction.Object);
    }

private async Task<Guid> ValidateAndHandle(CreateMeetingCommand command, CancellationToken cancellationToken)
{
    // First run the validation
    return await _validationBehavior.Handle(
        command,
        () => _handler.Handle(command, cancellationToken),
        cancellationToken);
}

    [Fact]
    public async Task Handle_ValidInPersonMeeting_ShouldCreateSuccessfully()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Test Meeting",
            Goal = "Test Goal", 
            Type = MeetingType.InPerson,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
            Location = "Test Location",
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { Guid.NewGuid() },
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh"
        }, Guid.NewGuid());

        _mockUnitOfWork.Setup(x => x.Meetings.ValidateMeetingTimeAsync(
            It.IsAny<Guid>(),
            It.IsAny<DateTime>(),
            It.IsAny<DateTime>(),
            It.IsAny<Guid?>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        // Act
        var result = await ValidateAndHandle(command, CancellationToken.None);

        // Assert
        Assert.NotEqual(Guid.Empty, result);
        _mockUnitOfWork.Verify(x => x.Meetings.AddAsync(
            It.Is<Meeting>(m => 
                m.Title == command.Dto.Title &&
                m.Type == MeetingType.InPerson &&
                m.Status == MeetingStatus.Scheduled),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Handle_RecurringMeeting_ShouldCreateWithPattern()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Daily Standup",
            Goal = "Team Sync",
            Type = MeetingType.Online,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddMinutes(30),
            ProjectId = Guid.NewGuid(),
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh",
            IsRecurring = true,
            RecurringPattern = new RecurringMeetingPatternDTO
            {
                RecurrenceType = RecurrenceType.Daily,
                Interval = 1,
                RecurringEndDate = DateTime.UtcNow.AddMonths(1)
            },
            MemberIds = new List<Guid> { Guid.NewGuid() }
        }, Guid.NewGuid());

        var futureInstances = new List<Meeting>
        {
            new() { Id = Guid.NewGuid(),Title = "Daily Standup",Goal = "Team Sync",Type = MeetingType.Online,StartTime = DateTime.UtcNow.AddDays(1),EndTime = DateTime.UtcNow.AddDays(1).AddMinutes(30),TimeZoneId = "Asia/Riyadh",Language = MeetingLanguage.English },
            new() { Id = Guid.NewGuid(),Title = "Daily Standup",Goal = "Team Sync",Type = MeetingType.Online,StartTime = DateTime.UtcNow.AddDays(2),EndTime = DateTime.UtcNow.AddDays(2).AddMinutes(30),TimeZoneId = "Asia/Riyadh",Language = MeetingLanguage.English }
        };

        _mockRecurringService.Setup(x => x.GenerateFutureInstances(
            It.IsAny<Meeting>(),
            It.IsAny<DateTime>()))
            .ReturnsAsync(futureInstances);

            _mockRecurringService.Setup(x => x.ValidatePattern(It.IsAny<RecurringMeetingPattern>()))
    .Callback<RecurringMeetingPattern>(pattern =>
    {
        if (pattern.Interval <= 0)
        {
            throw new ValidationException("Interval must be greater than 0");
        }
    });


        // Act
        var result = await ValidateAndHandle(command, CancellationToken.None);

        // Assert
        Assert.NotEqual(Guid.Empty, result);
        _mockUnitOfWork.Verify(x => x.RecurringMeetingPatterns.AddAsync(
            It.IsAny<RecurringMeetingPattern>(),
            It.IsAny<CancellationToken>()),
            Times.Once);
        _mockUnitOfWork.Verify(x => x.Meetings.AddAsync(
            It.IsAny<Meeting>(),
            It.IsAny<CancellationToken>()),
            Times.Exactly(3)); // Base meeting + 2 future instances
    }

    [Fact]
    public async Task Handle_UnauthorizedUser_ShouldThrowException()
    {
        // Arrange
        _mockAuthHelper.Setup(x => x.HasProjectPrivilege(
            It.IsAny<Guid>(),
            It.IsAny<Guid>(),
            It.IsAny<ProjectAspect>(),
            It.IsAny<PrivilegeLevel>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Test Meeting",
            Goal = "Test Goal",
            Type = MeetingType.InPerson,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
            Location = "Test Location",
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { Guid.NewGuid() },
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh"
        }, Guid.NewGuid());

        // Act & Assert
        await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            ValidateAndHandle(command, CancellationToken.None));
    }

    [Fact]
    public async Task Handle_DoneMeetingWithoutAudio_ShouldThrowValidationException()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Past Meeting",
            Goal = "Test Goal",
            Type = MeetingType.Done,
            StartTime = DateTime.UtcNow.AddDays(-2),
            EndTime = DateTime.UtcNow.AddDays(-2).AddHours(1),
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { Guid.NewGuid() },
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh"
        }, Guid.NewGuid());

       

        // Act & Assert
        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            ValidateAndHandle(command, CancellationToken.None));
        Assert.Contains("Audio file is required for Done meetings",
            exception.Message);
    }

    [Fact]
    public async Task Handle_TimeConflict_ShouldThrowValidationException()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Test Meeting",
            Goal = "Test Goal",
            Type = MeetingType.InPerson,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
            Location = "Test Location",
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { Guid.NewGuid() },
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh"
        }, Guid.NewGuid());

        _mockUnitOfWork.Setup(x => x.Meetings.ValidateMeetingTimeAsync(
            command.Dto.ProjectId,
            command.Dto.StartTime,
            command.Dto.EndTime,
            null,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

 
        // Act & Assert
        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            ValidateAndHandle(command, CancellationToken.None));
       
        Assert.Contains("Meeting time conflicts with an existing meeting", exception.Errors.Select(e => e.ErrorMessage));

    }

    [Fact]
    public async Task Handle_OnlineMeeting_ShouldCreateWithMeetingLink()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Online Meeting",
            Goal = "Test Goal",
            Type = MeetingType.Online,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { Guid.NewGuid() },
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh"
        }, Guid.NewGuid());

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.NotEqual(Guid.Empty, result);
        _mockUnitOfWork.Verify(x => x.Meetings.AddAsync(
            It.Is<Meeting>(m => 
                m.Type == MeetingType.Online &&
                m.AudioSource == AudioSource.MeetingService),
            It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Handle_ValidMeeting_ShouldSendNotifications()
    {
        // Arrange
        var memberId = Guid.NewGuid();
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Test Meeting",
            Goal = "Test Goal",
            Type = MeetingType.InPerson,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
            Location = "Test Location",
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { memberId },
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh"
        }, Guid.NewGuid());

       

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.NotEqual(Guid.Empty, result);
        _mockRabbitMQ.Verify(x => x.PublishNotificationAsync(
            It.Is<NotificationMessage>(n => 
                n.Type == NotificationType.Email &&
                n.Recipient == "member@test.com" &&
                n.Subject.Contains(command.Dto.Title))),
            Times.Once);
    }

    [Fact]
    public async Task Handle_RecurringMeeting_ShouldValidatePattern()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Daily Standup",
            Goal = "Team Sync",
            Type = MeetingType.Online,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddMinutes(30),
            ProjectId = Guid.NewGuid(),
            Language = MeetingLanguage.English,
            TimeZone = "Asia/Riyadh",
            IsRecurring = true,
            RecurringPattern = new RecurringMeetingPatternDTO
            {
                RecurrenceType = RecurrenceType.Daily,
                Interval = 0, // Invalid interval
                RecurringEndDate = DateTime.UtcNow.AddMonths(1)
            },
            MemberIds = new List<Guid> { Guid.NewGuid() }
        }, Guid.NewGuid());

        _mockRecurringService.Setup(x => x.ValidatePattern(It.IsAny<RecurringMeetingPattern>()))
            .Throws(new ValidationException("Interval must be greater than 0"));

        _mockUnitOfWork.Setup(x => x.Meetings.ValidateMeetingTimeAsync(
            It.IsAny<Guid>(),
            It.IsAny<DateTime>(),
            It.IsAny<DateTime>(),
            It.IsAny<Guid?>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        // Act & Assert
        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            ValidateAndHandle(command, CancellationToken.None));
        Assert.Contains("Interval must be greater than 0", exception.Message);
    }

    [Fact]
    public async Task Handle_InvalidTimeZone_ShouldThrowValidationException()
    {
        // Arrange
        var command = new CreateMeetingCommand(new CreateMeetingDTO
        {
            Title = "Test Meeting",
            Goal = "Test Goal",
            Type = MeetingType.InPerson,
            StartTime = DateTime.UtcNow.AddDays(1),
            EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
            Location = "Test Location",
            ProjectId = Guid.NewGuid(),
            MemberIds = new List<Guid> { Guid.NewGuid() },
            Language = MeetingLanguage.English,
            TimeZone = "Invalid/TimeZone"
        }, Guid.NewGuid());

        _mockUnitOfWork.Setup(x => x.Meetings.ValidateMeetingTimeAsync(
            It.IsAny<Guid>(),
            It.IsAny<DateTime>(),
            It.IsAny<DateTime>(),
            It.IsAny<Guid?>(),
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        _mockTimeZoneService.Setup(x => x.ValidateTimeZone(It.IsAny<string>()))
            .Returns(false);

        // Act & Assert
        var exception = await Assert.ThrowsAsync<ValidationException>(() =>
            ValidateAndHandle(command, CancellationToken.None)
        );
        Console.WriteLine(exception.Message);
        Console.WriteLine(exception.Errors.Select(e => e.ErrorMessage));
        Assert.Contains("Invalid timezone", exception.Message);
    }

    // ? GPT O1 Preview Generation.

    [Fact]
public async Task Handle_OnlineMeetingWithEmptyMembers_ShouldThrowValidationException()
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Online Meeting",
        Goal = "Test Goal",
        Type = MeetingType.Online,
        StartTime = DateTime.UtcNow.AddDays(1),
        EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid>(), // Empty member list
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Online meetings require at least one member", exception.Message);
}


[Fact]
public async Task Handle_MeetingWithInvalidMemberIds_ShouldThrowValidationException()
{
    // Arrange
    var invalidMemberId = Guid.NewGuid();
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Test Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddDays(1),
        EndTime = DateTime.UtcNow.AddDays(1).AddHours(1),
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { invalidMemberId },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Setup mock to return null for invalid member ID
    _mockUnitOfWork.Setup(x => x.OrganizationMembers.GetByIdAsync(
        invalidMemberId, It.IsAny<bool>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync((OrganizationMember)null!);

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("One or more invalid member IDs", exception.Message);
}
[Fact]
public async Task Handle_MeetingWithStartTimeAfterEndTime_ShouldThrowValidationException()
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Test Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(1), // End time before start time
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("End time must be after start time", exception.Message);
}


[Fact]
public async Task Handle_NonDoneMeetingWithPastStartTime_ShouldThrowValidationException()
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Past Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(-2), // Start time in the past
        EndTime = DateTime.UtcNow.AddHours(1),
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Meeting must start in the future for non-Done meetings", exception.Message);
}

[Fact]
public async Task Handle_DoneMeetingWithInvalidAudioFile_ShouldThrowValidationException()
{
    // Arrange
    var invalidAudioFile = new byte[0]; // Empty file
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Completed Meeting",
        Goal = "Test Goal",
        Type = MeetingType.Done,
        StartTime = DateTime.UtcNow.AddDays(-2),
        EndTime = DateTime.UtcNow.AddDays(-2).AddHours(1),
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        AudioFile = new FormFile(new MemoryStream(invalidAudioFile), 0, invalidAudioFile.Length, "AudioFile", "audio.mp3"),
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    _mockAudioStorage.Setup(x => x.ValidateAudioFileAsync(
        It.IsAny<IFormFile>(), 
        It.IsAny<CancellationToken>()))
        .ReturnsAsync(false);

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Invalid audio file format or size", exception.Message);
}

[Fact]
public async Task Handle_MeetingWithPastReminderTime_ShouldThrowValidationException()
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Test Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        ReminderTime = DateTime.UtcNow.AddHours(-1), // Reminder time in the past
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Reminder time must be in the future", exception.Message);
}

[Fact]
public async Task Handle_RecurringMeetingWithoutPattern_ShouldThrowValidationException()
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Recurring Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        IsRecurring = true,
        RecurringPattern = null, // Missing pattern
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Recurring pattern is required when IsRecurring is true", exception.Message);
}
[Fact]
public async Task Handle_MeetingWithTooManyMembers_ShouldThrowValidationException()
{
    // Arrange
    var memberIds = new List<Guid>();
    for (int i = 0; i < 101; i++) // 101 members
    {
        memberIds.Add(Guid.NewGuid());
    }

    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Large Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = memberIds,
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Cannot have more than 100 members", exception.Message);
}

[Fact]
public async Task Handle_MeetingWithExcessivelyLongTitle_ShouldThrowValidationException()
{
    // Arrange
    var longTitle = new string('A', 201); // 201 characters
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = longTitle,
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Title cannot exceed 200 characters", exception.Message);
}

[Fact]
public async Task Handle_MeetingWithNullTitle_ShouldThrowValidationException()
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = null!, // Null title
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    var exception = await Assert.ThrowsAsync<ValidationException>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    Assert.Contains("Title is required", exception.Message);
}

[Fact]
public async Task Handle_ExceptionDuringNotificationSending_ShouldNotFailMeetingCreation()
{
    // Arrange
    var memberId = Guid.NewGuid();
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Test Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        Location = "Test Location",
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { memberId },
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

   

    

    _mockRabbitMQ.Setup(x => x.PublishNotificationAsync(It.IsAny<NotificationMessage>()))
        .ThrowsAsync(new Exception("Notification service failed"));

    // Act
    var result = await ValidateAndHandle(command, CancellationToken.None);

    // Assert
    Assert.NotEqual(Guid.Empty, result);
    // Verify that the meeting was still created despite the notification failure
    _mockUnitOfWork.Verify(x => x.Meetings.AddAsync(It.IsAny<Meeting>(), It.IsAny<CancellationToken>()), Times.Once);
}

[Fact]
public async Task Handle_ExceptionAfterUploadingAudioFile_ShouldCleanupAudio()
{
    // Arrange
    var audioFile = new byte[] { 1, 2, 3 }; // Dummy data
    var formFile = new FormFile(new MemoryStream(audioFile), 0, audioFile.Length, "AudioFile", "audio.mp3");
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Done Meeting",
        Goal = "Test Goal",
        Type = MeetingType.Done,
        StartTime = DateTime.UtcNow.AddDays(-2),
        EndTime = DateTime.UtcNow.AddDays(-2).AddHours(1),
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        AudioFile = formFile,
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

   _mockAudioStorage.Setup(x => x.ValidateAudioFileAsync(
        It.IsAny<IFormFile>(), 
        It.IsAny<CancellationToken>()))
        .ReturnsAsync(true);

    // Setup audio upload
    _mockAudioStorage.Setup(x => x.UploadAudioAsync(
        It.IsAny<Guid>(), 
        It.IsAny<IFormFile>(), 
        It.IsAny<CancellationToken>()))
        .ReturnsAsync("http://audio.url");

    // Setup database error
    _mockUnitOfWork.Setup(x => x.CompleteAsync())
        .ThrowsAsync(new Exception("Database error"));

    // Setup audio deletion
    _mockAudioStorage.Setup(x => x.DeleteAudioAsync(
        "http://audio.url", 
        It.IsAny<CancellationToken>()))
        .Returns(Task.CompletedTask);

    // Act & Assert
    var exception = await Assert.ThrowsAsync<Exception>(() =>
        ValidateAndHandle(command, CancellationToken.None));
    // Assert.Contains("Database error", exception.Message);
    
    //Verify audio file cleanup
    _mockAudioStorage.Verify(
        x => x.DeleteAudioAsync("http://audio.url", It.IsAny<CancellationToken>()), 
        Times.Once);
    
}

[Fact]
public async Task Handle_ExceptionDuringTransaction_ShouldRollbackTransaction()
{
    // Arrange
  

    _mockUnitOfWork.Setup(x => x.CompleteAsync())
        .ThrowsAsync(new Exception("Database error"));

    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Transactional Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Location = "Test Location",
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    await Assert.ThrowsAsync<Exception>(() =>
        ValidateAndHandle(command, CancellationToken.None));

    // Verify that the transaction was rolled back
    _mockTransaction.Verify(x => x.RollbackAsync(It.IsAny<CancellationToken>()), Times.Once);
}


[Fact]
public async Task Handle_UnitOfWorkThrowsException_ShouldPropagateException()
{
    // Arrange
    _mockUnitOfWork.Setup(x => x.Meetings.AddAsync(
        It.IsAny<Meeting>(), It.IsAny<CancellationToken>()))
        .ThrowsAsync(new Exception("Database error"));

    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Dependency Failure Meeting",
        Goal = "Test Goal",
        Type = MeetingType.InPerson,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        Location = "Test Location",
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    // Act & Assert
    await Assert.ThrowsAsync<Exception>(() =>
        ValidateAndHandle(command, CancellationToken.None));
}

[Theory]
[InlineData(MeetingType.InPerson, MeetingStatus.Scheduled)]
[InlineData(MeetingType.Online, MeetingStatus.Scheduled)]
[InlineData(MeetingType.Done, MeetingStatus.Completed)]
public async Task Handle_MeetingTypeSetsCorrectStatus(MeetingType meetingType, MeetingStatus expectedStatus)
{
    // Arrange
    var command = new CreateMeetingCommand(new CreateMeetingDTO
    {
        Title = "Status Test Meeting",
        Goal = "Test Goal",
        Type = meetingType,
        StartTime = DateTime.UtcNow.AddHours(2),
        EndTime = DateTime.UtcNow.AddHours(3),
        ProjectId = Guid.NewGuid(),
        MemberIds = new List<Guid> { Guid.NewGuid() },
        AudioFile = meetingType == MeetingType.Done ? new FormFile(new MemoryStream([1, 2, 3]), 0, 3, "AudioFile", "audio.mp3") : null,
        Location = meetingType == MeetingType.InPerson ? "Test Location" : null,
        Language = MeetingLanguage.English,
        TimeZone = "Asia/Riyadh"
    }, Guid.NewGuid());

    Meeting capturedMeeting = null!;
    _mockUnitOfWork.Setup(x => x.Meetings.AddAsync(
        It.IsAny<Meeting>(), It.IsAny<CancellationToken>()))
        .Callback<Meeting, CancellationToken>((m, ct) => capturedMeeting = m)
        .Returns(Task.CompletedTask);

        _mockAudioStorage.Setup(x => x.ValidateAudioFileAsync(
        It.IsAny<IFormFile>(), 
        It.IsAny<CancellationToken>()))
        .ReturnsAsync(true);

    // Act
    await ValidateAndHandle(command, CancellationToken.None);

    // Assert
    Assert.Equal(expectedStatus, capturedMeeting.Status);
}


}