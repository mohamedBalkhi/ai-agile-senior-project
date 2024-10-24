using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Senior.AgileAI.BaseMgt.Application.DTOs;
using MediatR;

namespace Senior.AgileAI.BaseMgt.Application.Features.Auth.Commands
{
    public class SignUpCommand : IRequest<Guid> //the id of the created user
    {
        public SignUpDTO DTO { get; set; }

        public SignUpCommand(SignUpDTO dto)
        {
            DTO = dto;
        }
    }
}
