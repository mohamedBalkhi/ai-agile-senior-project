using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Senior.AgileAI.BaseMgt.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddMeetingMgtTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Meetings",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Title = table.Column<string>(type: "text", nullable: false),
                    Goal = table.Column<string>(type: "text", nullable: false),
                    Language = table.Column<int>(type: "integer", nullable: false),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    StartTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    EndTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    TimeZone = table.Column<string>(type: "text", nullable: false),
                    Location = table.Column<string>(type: "text", nullable: true),
                    MeetingUrl = table.Column<string>(type: "text", nullable: true),
                    AudioUrl = table.Column<string>(type: "text", nullable: true),
                    ReminderTime = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    Project_IdProject = table.Column<Guid>(type: "uuid", nullable: false),
                    Creator_IdOrganizationMember = table.Column<Guid>(type: "uuid", nullable: false),
                    RecurringPattern_IdRecurringPattern = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Meetings", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Meetings_OrganizationMembers_Creator_IdOrganizationMember",
                        column: x => x.Creator_IdOrganizationMember,
                        principalSchema: "public",
                        principalTable: "OrganizationMembers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_Meetings_Projects_Project_IdProject",
                        column: x => x.Project_IdProject,
                        principalSchema: "public",
                        principalTable: "Projects",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "MeetingMembers",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Meeting_IdMeeting = table.Column<Guid>(type: "uuid", nullable: false),
                    OrganizationMember_IdOrganizationMember = table.Column<Guid>(type: "uuid", nullable: false),
                    HasConfirmed = table.Column<bool>(type: "boolean", nullable: false),
                    CreatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MeetingMembers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_MeetingMembers_Meetings_Meeting_IdMeeting",
                        column: x => x.Meeting_IdMeeting,
                        principalSchema: "public",
                        principalTable: "Meetings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_MeetingMembers_OrganizationMembers_OrganizationMember_IdOrg~",
                        column: x => x.OrganizationMember_IdOrganizationMember,
                        principalSchema: "public",
                        principalTable: "OrganizationMembers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "RecurringMeetingPatterns",
                schema: "public",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    Meeting_IdMeeting = table.Column<Guid>(type: "uuid", nullable: false),
                    RecurrenceType = table.Column<int>(type: "integer", nullable: false),
                    Interval = table.Column<int>(type: "integer", nullable: false),
                    RecurringEndDate = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DaysOfWeek = table.Column<int>(type: "integer", nullable: true),
                    CreatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    UpdatedDate = table.Column<DateTime>(type: "timestamp without time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecurringMeetingPatterns", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RecurringMeetingPatterns_Meetings_Meeting_IdMeeting",
                        column: x => x.Meeting_IdMeeting,
                        principalSchema: "public",
                        principalTable: "Meetings",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MeetingMembers_Meeting_IdMeeting",
                schema: "public",
                table: "MeetingMembers",
                column: "Meeting_IdMeeting");

            migrationBuilder.CreateIndex(
                name: "IX_MeetingMembers_Meeting_IdMeeting_OrganizationMember_IdOrgan~",
                schema: "public",
                table: "MeetingMembers",
                columns: new[] { "Meeting_IdMeeting", "OrganizationMember_IdOrganizationMember" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_MeetingMembers_OrganizationMember_IdOrganizationMember",
                schema: "public",
                table: "MeetingMembers",
                column: "OrganizationMember_IdOrganizationMember");

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_Creator_IdOrganizationMember",
                schema: "public",
                table: "Meetings",
                column: "Creator_IdOrganizationMember");

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_Project_IdProject",
                schema: "public",
                table: "Meetings",
                column: "Project_IdProject");

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_StartTime",
                schema: "public",
                table: "Meetings",
                column: "StartTime");

            migrationBuilder.CreateIndex(
                name: "IX_Meetings_Status",
                schema: "public",
                table: "Meetings",
                column: "Status");

            migrationBuilder.CreateIndex(
                name: "IX_RecurringMeetingPatterns_Meeting_IdMeeting",
                schema: "public",
                table: "RecurringMeetingPatterns",
                column: "Meeting_IdMeeting",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_RecurringMeetingPatterns_RecurringEndDate",
                schema: "public",
                table: "RecurringMeetingPatterns",
                column: "RecurringEndDate");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MeetingMembers",
                schema: "public");

            migrationBuilder.DropTable(
                name: "RecurringMeetingPatterns",
                schema: "public");

            migrationBuilder.DropTable(
                name: "Meetings",
                schema: "public");
        }
    }
}
