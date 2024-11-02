using MediatR;
using Senior.AgileAI.BaseMgt.Domain.Entities;

#nullable disable

public class AddProjectReqFromFileCommand : IRequest<List<ProjectRequirement>>
{
    public Guid ProjectId { get; set; }
    public Stream FileStream { get; set; }
    public string FileName { get; set; }


}