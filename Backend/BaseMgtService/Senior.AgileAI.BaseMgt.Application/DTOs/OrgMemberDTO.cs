using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Senior.AgileAI.BaseMgt.Application.DTOs
{
    public class OrgMemberDTO
    {
        public required List<string> Emails { get; set; }  //? only emails is needed all other info will be default.

    }
}