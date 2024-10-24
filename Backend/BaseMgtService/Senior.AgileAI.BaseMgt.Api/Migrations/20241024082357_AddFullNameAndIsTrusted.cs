using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddFullNameAndIsTrusted : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "isAdmin",
                schema: "public",
                table: "Users",
                newName: "IsAdmin");

            migrationBuilder.RenameColumn(
                name: "Name",
                schema: "public",
                table: "Users",
                newName: "FUllName");

            migrationBuilder.AddColumn<string>(
                name: "Code",
                schema: "public",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsTrusted",
                schema: "public",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<string>(
                name: "Logo",
                schema: "public",
                table: "Organizations",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Code",
                schema: "public",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "IsTrusted",
                schema: "public",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Logo",
                schema: "public",
                table: "Organizations");

            migrationBuilder.RenameColumn(
                name: "IsAdmin",
                schema: "public",
                table: "Users",
                newName: "isAdmin");

            migrationBuilder.RenameColumn(
                name: "FUllName",
                schema: "public",
                table: "Users",
                newName: "Name");
        }
    }
}
