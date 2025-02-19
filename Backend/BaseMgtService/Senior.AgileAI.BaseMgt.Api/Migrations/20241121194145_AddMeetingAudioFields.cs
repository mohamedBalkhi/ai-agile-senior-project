using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMeetingAudioFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TimeZone",
                schema: "public",
                table: "Meetings");

            migrationBuilder.AddColumn<int>(
                name: "AudioSource",
                schema: "public",
                table: "Meetings",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "AudioStatus",
                schema: "public",
                table: "Meetings",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<DateTime>(
                name: "AudioUploadedAt",
                schema: "public",
                table: "Meetings",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TimeZoneId",
                schema: "public",
                table: "Meetings",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                defaultValue: "");

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
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Meetings_AudioStatus",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_AudioUploadedAt",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AudioSource",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AudioStatus",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AudioUploadedAt",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "TimeZoneId",
                schema: "public",
                table: "Meetings");

            migrationBuilder.AddColumn<string>(
                name: "TimeZone",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: false,
                defaultValue: "");
        }
    }
}
