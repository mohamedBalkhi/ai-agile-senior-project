using MediatR;

#nullable disable

public class AddProjectReqFromFileCommand : IRequest<bool>
{
    public Guid ProjectId { get; set; }
    public Stream FileStream { get; set; }
    public string FileName { get; set; }


}