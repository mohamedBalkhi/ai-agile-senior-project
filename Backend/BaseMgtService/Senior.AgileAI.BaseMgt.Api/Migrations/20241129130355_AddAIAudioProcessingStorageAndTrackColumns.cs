using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddAIAudioProcessingStorageAndTrackColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<List<string>>(
                name: "AIKeyPoints",
                schema: "public",
                table: "Meetings",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AIMainLanguage",
                schema: "public",
                table: "Meetings",
                type: "character varying(10)",
                maxLength: 10,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "AIProcessedAt",
                schema: "public",
                table: "Meetings",
                type: "timestamp without time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "AIProcessingStatus",
                schema: "public",
                table: "Meetings",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "AIProcessingToken",
                schema: "public",
                table: "Meetings",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AISummary",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "AITranscript",
                schema: "public",
                table: "Meetings",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "AIKeyPoints",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AIMainLanguage",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AIProcessedAt",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AIProcessingStatus",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AIProcessingToken",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AISummary",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "AITranscript",
                schema: "public",
                table: "Meetings");
        }
    }
}
