﻿using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class MakeOrgManagerOptionalFollowUp : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<Guid>(
                name: "OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<Guid>(
                name: "OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);
        }
    }
}
