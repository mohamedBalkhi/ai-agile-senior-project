using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMeetingReminderAndActualEndTime : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Projects_Project_IdProject",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_AudioStatus",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_AudioUploadedAt",
                schema: "public",
                table: "Meetings");

            migrationBuilder.AlterColumn<string>(
                name: "Title",
                schema: "public",
                table: "Meetings",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<DateTime>(
                name: "ReminderTime",
                schema: "public",
                table: "Meetings",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified),
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Location",
                schema: "public",
                table: "Meetings",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Goal",
                schema: "public",
                table: "Meetings",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "AudioUrl",
                schema: "public",
                table: "Meetings",
                type: "character varying(1000)",
                maxLength: 1000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ActualEndTime",
                schema: "public",
                table: "Meetings",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "ReminderSent",
                schema: "public",
                table: "Meetings",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "RecurringMeetingExceptions",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    RecurringPattern_IdRecurringPattern = table.Column<Guid>(type: "uuid", nullable: false),
                    ExceptionDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    Reason = table.Column<string>(type: "text", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecurringMeetingExceptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RecurringMeetingExceptions_RecurringMeetingPatterns_Recurri~",
                        column: x => x.RecurringPattern_IdRecurringPattern,
                        principalSchema: "public",
                        principalTable: "RecurringMeetingPatterns",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "Meetings",
                column: "RecurringPattern_IdRecurringPattern",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RecurringMeetingExceptions_ExceptionDate",
                schema: "public",
                table: "RecurringMeetingExceptions",
                column: "ExceptionDate");

            migrationBuilder.CreateIndex(
                name: "IX_RecurringMeetingExceptions_RecurringPattern_IdRecurringPat~1",
                schema: "public",
                table: "RecurringMeetingExceptions",
                columns: new[] { "RecurringPattern_IdRecurringPattern", "ExceptionDate" });

            migrationBuilder.CreateIndex(
                name: "IX_RecurringMeetingExceptions_RecurringPattern_IdRecurringPatt~",
                schema: "public",
                table: "RecurringMeetingExceptions",
                column: "RecurringPattern_IdRecurringPattern");

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Projects_Project_IdProject",
                schema: "public",
                table: "Meetings",
                column: "Project_IdProject",
                principalSchema: "public",
                principalTable: "Projects",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Projects_Project_IdProject",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropTable(
                name: "RecurringMeetingExceptions",
                schema: "public");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "ActualEndTime",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "ReminderSent",
                schema: "public",
                table: "Meetings");

            migrationBuilder.AlterColumn<string>(
                name: "Title",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(200)",
                oldMaxLength: 200);

            migrationBuilder.AlterColumn<DateTime>(
                name: "ReminderTime",
                schema: "public",
                table: "Meetings",
                type: "timestamp with time zone",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "timestamp with time zone");

            migrationBuilder.AlterColumn<string>(
                name: "Location",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(500)",
                oldMaxLength: 500,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Goal",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(1000)",
                oldMaxLength: 1000);

            migrationBuilder.AlterColumn<string>(
                name: "AudioUrl",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "character varying(1000)",
                oldMaxLength: 1000,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_AudioStatus",
                schema: "public",
                table: "Meetings",
                column: "AudioStatus");

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_AudioUploadedAt",
                schema: "public",
                table: "Meetings",
                column: "AudioUploadedAt");

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Projects_Project_IdProject",
                schema: "public",
                table: "Meetings",
                column: "Project_IdProject",
                principalSchema: "public",
                principalTable: "Projects",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
