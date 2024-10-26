using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class LinkedOrgWithUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                schema: "public",
                table: "Organizations");

            migrationBuilder.DropIndex(
                name: "IX_Organizations_OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                schema: "public",
                table: "Organizations",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_Organizations_OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Organizations_Users_OrganizationManager_IdOrganizationManag~",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                principalSchema: "public",
                principalTable: "Users",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Organizations_Users_OrganizationManager_IdOrganizationManag~",
                schema: "public",
                table: "Organizations");

            migrationBuilder.DropIndex(
                name: "IX_Organizations_OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations");

            migrationBuilder.DropColumn(
                name: "IsActive",
                schema: "public",
                table: "Organizations");

            migrationBuilder.CreateIndex(
                name: "IX_Organizations_OrganizationManager_IdOrganizationManager",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager");

            migrationBuilder.AddForeignKey(
                name: "FK_Organizations_OrganizationMembers_OrganizationManager_IdOrg~",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                principalSchema: "public",
                principalTable: "OrganizationMembers",
                principalColumn: "Id");
        }
    }
}
