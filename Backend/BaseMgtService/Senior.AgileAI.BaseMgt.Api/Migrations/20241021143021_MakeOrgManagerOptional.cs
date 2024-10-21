using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class MakeOrgManagerOptional : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                schema: "public",
                table: "Organizations");

            migrationBuilder.AddForeignKey(
                name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                principalSchema: "public",
                principalTable: "OrganizationMembers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                schema: "public",
                table: "Organizations");

            migrationBuilder.AddForeignKey(
                name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                principalSchema: "public",
                principalTable: "OrganizationMembers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
