using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class SetOnDeleteCascadeBetweenUserAndOrg : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Organizations_Users_OrganizationManager_IdOrganizationManag~",
                schema: "public",
                table: "Organizations");

            migrationBuilder.AddForeignKey(
                name: "FK_Organizations_Users_OrganizationManager_IdOrganizationManag~",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                principalSchema: "public",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Organizations_Users_OrganizationManager_IdOrganizationManag~",
                schema: "public",
                table: "Organizations");

            migrationBuilder.AddForeignKey(
                name: "FK_Organizations_Users_OrganizationManager_IdOrganizationManag~",
                schema: "public",
                table: "Organizations",
                column: "OrganizationManager_IdOrganizationManager",
                principalSchema: "public",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
