using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class last_check : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Status",
                schema: "public",
                table: "Users");

            migrationBuilder.RenameColumn(
                name: "Users",
                schema: "public",
                table: "ProjectPrivileges",
                newName: "Tasks");

            migrationBuilder.AddColumn<bool>(
                name: "IsActive",
                schema: "public",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AlterColumn<bool>(
                name: "Status",
                schema: "public",
                table: "Projects",
                type: "boolean",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<int>(
                name: "Members",
                schema: "public",
                table: "ProjectPrivileges",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "Requirements",
                schema: "public",
                table: "ProjectPrivileges",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "MyProperty",
                schema: "public",
                table: "OrganizationMembers",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsActive",
                schema: "public",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Members",
                schema: "public",
                table: "ProjectPrivileges");

            migrationBuilder.DropColumn(
                name: "Requirements",
                schema: "public",
                table: "ProjectPrivileges");

            migrationBuilder.DropColumn(
                name: "MyProperty",
                schema: "public",
                table: "OrganizationMembers");

            migrationBuilder.RenameColumn(
                name: "Tasks",
                schema: "public",
                table: "ProjectPrivileges",
                newName: "Users");

            migrationBuilder.AddColumn<string>(
                name: "Status",
                schema: "public",
                table: "Users",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AlterColumn<string>(
                name: "Status",
                schema: "public",
                table: "Projects",
                type: "text",
                nullable: false,
                oldClrType: typeof(bool),
                oldType: "boolean");
        }
    }
}
