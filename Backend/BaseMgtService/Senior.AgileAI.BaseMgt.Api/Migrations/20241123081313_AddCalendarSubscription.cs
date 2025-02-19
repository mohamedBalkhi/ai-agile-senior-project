using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddCalendarSubscription : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "CalendarSubscriptions",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    User_IdUser = table.Column<Guid>(type: "uuid", nullable: false),
                    Token = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    FeedType = table.Column<int>(type: "integer", nullable: false),
                    Project_IdProject = table.Column<Guid>(type: "uuid", nullable: true),
                    RecurringPattern_IdRecurringPattern = table.Column<Guid>(type: "uuid", nullable: true),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    CreatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CalendarSubscriptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CalendarSubscriptions_Projects_Project_IdProject",
                        column: x => x.Project_IdProject,
                        principalSchema: "public",
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CalendarSubscriptions_RecurringMeetingPatterns_RecurringPat~",
                        column: x => x.RecurringPattern_IdRecurringPattern,
                        principalSchema: "public",
                        principalTable: "RecurringMeetingPatterns",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CalendarSubscriptions_Users_User_IdUser",
                        column: x => x.User_IdUser,
                        principalSchema: "public",
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_CalendarSubscriptions_ExpiresAt",
                schema: "public",
                table: "CalendarSubscriptions",
                column: "ExpiresAt");

            migrationBuilder.CreateIndex(
                name: "IX_CalendarSubscriptions_IsActive_ExpiresAt",
                schema: "public",
                table: "CalendarSubscriptions",
                columns: new[] { "IsActive", "ExpiresAt" });

            migrationBuilder.CreateIndex(
                name: "IX_CalendarSubscriptions_Project_IdProject",
                schema: "public",
                table: "CalendarSubscriptions",
                column: "Project_IdProject");

            migrationBuilder.CreateIndex(
                name: "IX_CalendarSubscriptions_RecurringPattern_IdRecurringPattern",
                schema: "public",
                table: "CalendarSubscriptions",
                column: "RecurringPattern_IdRecurringPattern");

            migrationBuilder.CreateIndex(
                name: "IX_CalendarSubscriptions_Token",
                schema: "public",
                table: "CalendarSubscriptions",
                column: "Token",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CalendarSubscriptions_User_IdUser",
                schema: "public",
                table: "CalendarSubscriptions",
                column: "User_IdUser");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "CalendarSubscriptions",
                schema: "public");
        }
    }
}
