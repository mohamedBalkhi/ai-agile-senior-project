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

            migrationBuilder.DropColumn(
                name: "Status", 
                schema: "public",
                table: "Projects");

            migrationBuilder.AddColumn<bool>(
                name: "Status",
                schema: "public", 
                table: "Projects",
                type: "boolean",
                nullable: false,
                defaultValue: false);

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
