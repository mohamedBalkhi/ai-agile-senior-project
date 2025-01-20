using Moq;
using Xunit;
using Senior.AgileAI.BaseMgt.Application.Contracts.Infrastructure;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commands;
using Senior.AgileAI.BaseMgt.Application.Features.projects.commandhandlers;
using Senior.AgileAI.BaseMgt.Domain.Entities;
using Senior.AgileAI.BaseMgt.Application.Common.Authorization;
using Senior.AgileAI.BaseMgt.Application.Models;
using Senior.AgileAI.BaseMgt.Domain.Enums;

namespace Senior.AgileAI.BaseMgt.Tests.Unit.Projects.Commands;

public class AssignMemberCommandHandlerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IProjectAuthorizationHelper> _mockAuthHelper;
    private readonly Mock<IRabbitMQService> _mockRabbitMQ;
    private readonly Mock<IProjectPrivilegeRepository> _mockProjectPrivilegeRepo;
    private readonly Mock<IOrganizationMemberRepository> _mockOrgMemberRepo;
    private readonly Mock<IProjectRepository> _mockProjectRepo;
    private readonly Mock<INotificationTokenRepository> _mockNotificationTokenRepo;
    private readonly AssignMemberCommandHandler _handler;

    public AssignMemberCommandHandlerTests()
    {
        _mockUnitOfWork = new Mock<IUnitOfWork>();
        _mockAuthHelper = new Mock<IProjectAuthorizationHelper>();
        _mockRabbitMQ = new Mock<IRabbitMQService>();
        _mockProjectPrivilegeRepo = new Mock<IProjectPrivilegeRepository>();
        _mockOrgMemberRepo = new Mock<IOrganizationMemberRepository>();
        _mockProjectRepo = new Mock<IProjectRepository>();
        _mockNotificationTokenRepo = new Mock<INotificationTokenRepository>();

        _mockUnitOfWork.Setup(uow => uow.ProjectPrivileges).Returns(_mockProjectPrivilegeRepo.Object);
        _mockUnitOfWork.Setup(uow => uow.OrganizationMembers).Returns(_mockOrgMemberRepo.Object);
        _mockUnitOfWork.Setup(uow => uow.Projects).Returns(_mockProjectRepo.Object);
        _mockUnitOfWork.Setup(uow => uow.NotificationTokens).Returns(_mockNotificationTokenRepo.Object);

        _handler = new AssignMemberCommandHandler(_mockUnitOfWork.Object, _mockAuthHelper.Object, _mockRabbitMQ.Object);
    }

    [Fact]
    public async Task Handle_ValidAssignment_ShouldSendNotifications()
    {
        // Arrange
        var command = new AssignMemberCommand(new Application.DTOs.AssignMemberDTO
        {
            ProjectId = Guid.NewGuid(),
            MemberId = Guid.NewGuid(),
            MeetingsPrivilegeLevel = PrivilegeLevel.Read,
            MembersPrivilegeLevel = PrivilegeLevel.Read,
            RequirementsPrivilegeLevel = PrivilegeLevel.Read,
            TasksPrivilegeLevel = PrivilegeLevel.Read,
            SettingsPrivilegeLevel = PrivilegeLevel.Read
        }, Guid.NewGuid());

        var project = new Project 
        { 
            Id = command.Dto.ProjectId, 
            Name = "Test Project",
            Description = "Test Description",
            Status = true,
            Organization_IdOrganization = Guid.NewGuid()
        };

        var user = new User 
        { 
            Id = command.Dto.MemberId, 
            Email = "test@test.com",
            FUllName = "Test User",
            Password = "hashedPassword",
            BirthDate = DateOnly.FromDateTime(DateTime.UtcNow.AddYears(-20)),
            IsActive = true,
            IsTrusted = true,
            IsAdmin = false,
            Deactivated = false,
            Country_IdCountry = Guid.NewGuid()
        };

        var member = new OrganizationMember 
        { 
            Id = Guid.NewGuid(),
            User = user,
            User_IdUser = user.Id,
            IsManager = false,
            HasAdministrativePrivilege = false,
            Organization_IdOrganization = Guid.NewGuid()
        };

        var fcmTokens = new List<NotificationToken> 
        { 
            new NotificationToken 
            { 
                Token = "token1",
                DeviceId = "device1",
                User_IdUser = user.Id
            },
            new NotificationToken 
            { 
                Token = "token2",
                DeviceId = "device2",
                User_IdUser = user.Id
            }
        };

        _mockAuthHelper.Setup(h => h.HasProjectPrivilege(
            It.IsAny<Guid>(), 
            It.IsAny<Guid>(), 
            It.IsAny<ProjectAspect>(), 
            It.IsAny<PrivilegeLevel>(), 
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        _mockProjectRepo.Setup(r => r.GetByIdAsync(
            It.IsAny<Guid>(), 
            It.IsAny<CancellationToken>(),
            It.IsAny<bool>()))
            .ReturnsAsync(project);

        _mockOrgMemberRepo.Setup(r => r.GetByUserId(
            command.Dto.MemberId, 
            true,
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(member);

        _mockNotificationTokenRepo.Setup(r => r.GetTokensByUserId(
            It.IsAny<Guid>(), 
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(fcmTokens);

        _mockProjectPrivilegeRepo.Setup(r => r.GetProjectPrivilegeByMember(
            It.IsAny<Guid>(), 
            It.IsAny<Guid>(), 
            It.IsAny<CancellationToken>()))
            .ReturnsAsync((ProjectPrivilege)null!);

        _mockProjectPrivilegeRepo.Setup(r => r.AddPrivilegeAsync(
            It.IsAny<ProjectPrivilege>(), 
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        Assert.True(result);
        
        // Verify email notification was sent
        _mockRabbitMQ.Verify(r => r.PublishNotificationAsync(It.Is<NotificationMessage>(m => 
            m.Type == NotificationType.Email && 
            m.Recipient == member.User.Email &&
            m.Subject.Contains(project.Name))), Times.Once);

        // Verify FCM notifications were sent (one for each token)
        _mockRabbitMQ.Verify(r => r.PublishNotificationAsync(It.Is<NotificationMessage>(m => 
            m.Type == NotificationType.Firebase)), Times.Exactly(fcmTokens.Count));
    }

   [Fact]
public async Task Handle_UnauthorizedAccess_ShouldThrowException()
{
    // Arrange
    var command = new AssignMemberCommand(new Application.DTOs.AssignMemberDTO
    {
        ProjectId = Guid.NewGuid()
    }, Guid.NewGuid());

    // Setup project to exist
    var project = new Project 
    { 
        Id = command.Dto.ProjectId, 
        Name = "Test Project",
        Description = "Test Description",
        Status = true,
        Organization_IdOrganization = Guid.NewGuid()
    };

    _mockProjectRepo.Setup(r => r.GetByIdAsync(
        It.IsAny<Guid>(), 
        It.IsAny<CancellationToken>(),
        It.IsAny<bool>()))
        .ReturnsAsync(project);

    _mockAuthHelper.Setup(h => h.HasProjectPrivilege(
        It.IsAny<Guid>(), 
        It.IsAny<Guid>(), 
        It.IsAny<ProjectAspect>(), 
        It.IsAny<PrivilegeLevel>(), 
        It.IsAny<CancellationToken>()))
        .ReturnsAsync(false);

    // Act & Assert
    await Assert.ThrowsAsync<UnauthorizedAccessException>(() => 
            _handler.Handle(command, CancellationToken.None));
    }

    [Fact]
    public async Task Handle_ProjectNotFound_ShouldThrowException()
    {
        // Arrange
        var command = new AssignMemberCommand(new Application.DTOs.AssignMemberDTO
        {
            ProjectId = Guid.NewGuid()
        }, Guid.NewGuid());

        _mockAuthHelper.Setup(h => h.HasProjectPrivilege(
            It.IsAny<Guid>(), 
            It.IsAny<Guid>(), 
            It.IsAny<ProjectAspect>(), 
            It.IsAny<PrivilegeLevel>(), 
            It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        _mockProjectRepo.Setup(r => r.GetByIdAsync(
            It.IsAny<Guid>(), 
            It.IsAny<CancellationToken>(),
            It.IsAny<bool>()))
            .ReturnsAsync((Project)null!);

        // Act & Assert
        await Assert.ThrowsAsync<NotFoundException>(() => 
            _handler.Handle(command, CancellationToken.None));
    }
} 