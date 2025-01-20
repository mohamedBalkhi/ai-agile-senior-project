using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddOriginalMeetingSelfReference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "OriginalMeeting_IdMeeting",
                schema: "public",
                table: "Meetings",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_OriginalMeeting_IdMeeting",
                schema: "public",
                table: "Meetings",
                column: "OriginalMeeting_IdMeeting");

            migrationBuilder.AddForeignKey(
                name: "FK_Meetings_Meetings_OriginalMeeting_IdMeeting",
                schema: "public",
                table: "Meetings",
                column: "OriginalMeeting_IdMeeting",
                principalSchema: "public",
                principalTable: "Meetings",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Meetings_Meetings_OriginalMeeting_IdMeeting",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropIndex(
                name: "IX_Meetings_OriginalMeeting_IdMeeting",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "OriginalMeeting_IdMeeting",
                schema: "public",
                table: "Meetings");
        }
    }
}
