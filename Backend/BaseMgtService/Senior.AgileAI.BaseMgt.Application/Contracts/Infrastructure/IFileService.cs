using Microsoft.AspNetCore.Http;
using System;
using System.Threading;
using System.Threading.Tasks;

public interface IFileService
{
    Task<string> SaveFileAsync(IFormFile file, string folder, CancellationToken cancellationToken = default);
    Task DeleteFileAsync(string filePath);
} 