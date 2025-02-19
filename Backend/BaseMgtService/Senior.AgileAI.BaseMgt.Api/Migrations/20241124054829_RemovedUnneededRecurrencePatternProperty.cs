using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class RemovedUnneededRecurrencePatternProperty : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Meetings_RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "Meetings");

            migrationBuilder.DropColumn(
                name: "RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "Meetings");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "Meetings",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "Meetings",
                column: "RecurringPattern_IdRecurringPattern",
                unique: true);
        }
    }
}
