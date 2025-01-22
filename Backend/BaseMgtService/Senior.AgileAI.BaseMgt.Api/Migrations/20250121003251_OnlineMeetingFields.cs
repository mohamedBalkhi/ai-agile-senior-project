using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class OnlineMeetingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "LiveKitRoomName",
                schema: "public",
                table: "Meetings",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "LiveKitRoomSid",
                schema: "public",
                table: "Meetings",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "OnlineMeetingEndedAt",
                schema: "public",
                table: "Meetings",
                type: "timestamp without time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "OnlineMeetingStartedAt",
                schema: "public",
                table: "Meetings",
                type: "timestamp without time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "OnlineMeetingStatus",
                schema: "public",
                table: "Meetings",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "LiveKitRoomName",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "LiveKitRoomSid",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "OnlineMeetingEndedAt",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "OnlineMeetingStartedAt",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "OnlineMeetingStatus",
                schema: "public",
                table: "Meetings");
        }
    }
}
